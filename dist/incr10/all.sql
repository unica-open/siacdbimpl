/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-5228 INIZIO
alter table siac_dwh_ordinativo_pagamento add column soggetto_csc_id integer;
alter table siac_dwh_liquidazione add column soggetto_csc_id integer;

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
  desc_siope,
  soggetto_csc_id -- SIAC-5228
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
tb.soggetto_id_da soggetto_csc_id -- SIAC-5228
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
mif.mif_ord_class_codice_cge, mif.descr_siope,
modpagcsc.soggetto_id_da,      -- SIAC-5228
modpagcsc.oil_relaz_tipo_code, -- SIAC-5228
modpagcsc.relaz_tipo_code,     -- SIAC-5228
modpagcsc.relaz_tipo_desc      -- SIAC-5228
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
left join modpagcsc on ord_pag.ord_id = modpagcsc.ord_id
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
v_sogg_id INTEGER := null; -- Assume il valore di v_soggetto_id_intestatario o se e' null di v_soggetto_id
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


v_soggetto_csc_id integer:=null; -- SIAC-5228

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

v_soggetto_csc_id:=null; -- SIAC-5228

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

-- Sezione per le modalita' di pagamento
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

-- SIAC-5228 INIZIO

SELECT rel.soggetto_id_da, oil.oil_relaz_tipo_code, tipo.relaz_tipo_code, tipo.relaz_tipo_desc
INTO v_soggetto_csc_id, v_tipo_cessione, v_cod_cessione, v_desc_cessione
FROM siac_r_subdoc_liquidazione subdocliq, siac_r_subdoc_modpag subdocmodpag, siac_r_soggrel_modpag sogrel,
     siac_r_soggetto_relaz rel, siac_r_oil_relaz_tipo roil, siac_d_relaz_tipo tipo , siac_d_oil_relaz_tipo oil
WHERE  subdocliq.liq_id = v_liq_id
AND    oil.oil_relaz_tipo_code = 'CSC'
AND    subdocliq.subdoc_id = subdocmodpag.subdoc_id
AND    sogrel.modpag_id = subdocmodpag.modpag_id
AND    sogrel.soggetto_relaz_id = rel.soggetto_relaz_id
AND    rel.relaz_tipo_id = roil.relaz_tipo_id
AND    tipo.relaz_tipo_id = roil.relaz_tipo_id
AND    oil.oil_relaz_tipo_id = roil.oil_relaz_tipo_id
AND    p_data BETWEEN subdocliq.validita_inizio AND COALESCE(subdocliq.validita_fine, p_data)
AND    p_data BETWEEN subdocmodpag.validita_inizio AND COALESCE(subdocmodpag.validita_fine, p_data)
AND    p_data BETWEEN sogrel.validita_inizio AND COALESCE(sogrel.validita_fine, p_data)
AND    p_data BETWEEN rel.validita_inizio AND COALESCE(rel.validita_fine, p_data)
AND    p_data BETWEEN roil.validita_inizio AND COALESCE(roil.validita_fine, p_data)
AND    subdocliq.data_cancellazione is null
AND    subdocmodpag.data_cancellazione is null
AND    sogrel.data_cancellazione is null
AND    rel.data_cancellazione is null
AND    roil.data_cancellazione is null
AND    tipo.data_cancellazione is null
AND    oil.data_cancellazione is null;

-- SIAC_5228 FINE

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
   tipo_cessione,  -- 04.07.2017 Sofia SIAC-5040
   cod_cessione,   -- 04.07.2017 Sofia SIAC-5040
   desc_cessione,  -- 04.07.2017 Sofia SIAC-5040
   soggetto_csc_id -- SIAC-5228
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
          v_tipo_cessione,  -- 04.07.2017 Sofia SIAC-5040
          v_cod_cessione,   -- 04.07.2017 Sofia SIAC-5040
          v_desc_cessione,  -- 04.07.2017 Sofia SIAC-5040
          v_soggetto_csc_id -- SIAC-5228
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


insert into siac_r_oil_relaz_tipo
(
  relaz_tipo_id,
  oil_relaz_tipo_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select tipo.relaz_tipo_id,
       oil.oil_relaz_tipo_id,
       now(),
       tipo.ente_proprietario_id,
       'admin-SIAC-5228'
from siac_d_relaz_tipo tipo, siac_d_oil_relaz_tipo oil
where tipo.relaz_tipo_code='CSC'
and   oil.ente_proprietario_id=tipo.ente_proprietario_id
and   oil.oil_relaz_tipo_code='CSC'
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
and   oil.data_cancellazione is null
and   oil.validita_fine is null
and   not exists
(
select 1
from siac_r_oil_relaz_tipo r1
where r1.ente_proprietario_id=tipo.ente_proprietario_id
and   r1.relaz_tipo_id=tipo.relaz_tipo_id
and   r1.oil_relaz_tipo_id=oil.oil_relaz_tipo_id
and   r1.data_cancellazione is null
and   r1.validita_fine is null
);


-- SIAC-5228 FINE


-- SIAC-5247 INIZIO Maurizio

DROP FUNCTION siac."BILR110_Allegato_9_bilancio_di_gestione_entrate"(p_ente_prop_id integer, p_anno varchar, p_ele_variazioni varchar);
DROP FUNCTION siac."BILR111_Allegato_9_bil_gest_spesa_mpt"(p_ente_prop_id integer, p_anno varchar, p_disavanzo boolean, ele_variazioni varchar);
DROP FUNCTION siac."BILR112_Allegato_9_bill_gest_quadr_riass_gen_entrate"(p_ente_prop_id integer, p_anno varchar, p_altri_imp boolean, ele_variazioni varchar);
DROP FUNCTION siac."BILR112_Allegato_9_bill_gest_quadr_riass_gen_spese"(p_ente_prop_id integer, p_anno varchar, p_disavanzo boolean, ele_variazioni varchar);
DROP FUNCTION siac."BILR997_tipo_capitolo_dei_report_variaz"(p_ente_prop_id integer, p_anno varchar, p_ele_variazioni varchar);

CREATE OR REPLACE FUNCTION siac."BILR110_Allegato_9_bilancio_di_gestione_entrate" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar,
  p_num_provv_var_peg integer,
  p_anno_provv_var_peg varchar,
  p_tipo_provv_var_peg varchar,
  p_num_provv_var_bil integer,
  p_anno_provv_var_bil varchar,
  p_tipo_provv_var_bil varchar,
  p_code_sac_direz_peg varchar,
  p_code_sac_sett_peg varchar,
  p_code_sac_direz_bil varchar,
  p_code_sac_sett_bil varchar
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
  previsioni_anno_prec numeric,
  previsioni_anno_prec_comp numeric,
  previsioni_anno_prec_cassa numeric,
  display_error varchar
) AS
$body$
DECLARE
classifBilRec record;
elencoVarRec  record;

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
annoPrec VARCHAR;
importo_cassa_app numeric;
importo_competenza_app numeric;
intApp INTEGER;
strApp VARCHAR;
sql_query VARCHAR;
v_fam_titolotipologiacategoria varchar:='00003';
-- ALESSANDRO - SIAC-5208 - oltre 4 variazioni, il codice si sfonda
x_array VARCHAR [];
-- ALESSANDRO - SIAC-5208 - FINE
contaParVarPeg integer;
contaParVarBil integer;

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 
annoPrec:=((p_anno::INTEGER)-1)::VARCHAR;  

TipoImpComp='STA';  -- competenza
TipoImpresidui='STR'; -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
TipoImpCassa ='SCA'; ----- previsioni di cassa
elemTipoCode:='CAP-EG'; -- tipo capitolo previsione

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
previsioni_anno_prec:=0;
stanziamento_prev_cassa_anno:=0;
display_error='';
contaParVarPeg:=0;
contaParVarBil:=0;

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  -- ALESSANDRO - SIAC-5208 - non posso castare l'intera stringa a integer: spezzo e parsifico pezzo a pezzo
  x_array = string_to_array(p_ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    --strApp=REPLACE(p_ele_variazioni,',','');
    --raise notice 'VAR: %', strApp;
    intApp = strApp::INTEGER;
  END LOOP;
  -- ALESSANDRO - SIAC-5208 - FINE
END IF;

    /* 22/09/2017: parametri nuovi, controllo che se e' passato uno tra numero/anno/tipo
    	provvedimento di variazione di PEG o di BILANCIO, siano passati anche
        gli altri 2. */
if p_num_provv_var_peg IS NOT  NULL THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if p_anno_provv_var_peg IS NOT  NULL AND p_anno_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if p_tipo_provv_var_peg IS NOT  NULL AND p_tipo_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if contaParVarPeg not in (0,3) then
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di PEG''';
    return next;
    return;        
end if;

if p_num_provv_var_bil IS NOT  NULL THEN
	contaParVarBil=contaParVarBil+1;
end if;
if p_anno_provv_var_bil IS NOT  NULL AND p_anno_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
end if;
if p_tipo_provv_var_bil IS NOT  NULL AND p_tipo_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
end if;
if contaParVarBil not in (0,3) then
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di Bilancio''';
    return next;
    return;        
end if;

select fnc_siac_random_user()
into	user_table;


/*
insert into  siac_rep_tit_tip_cat_riga_anni
select v.*,user_table from
(SELECT v3.classif_tipo_desc AS classif_tipo_desc1, v3.classif_id AS titolo_id,
    v3.classif_code AS titolo_code, v3.classif_desc AS titolo_desc,
    v3.validita_inizio AS titolo_validita_inizio,
    v3.validita_fine AS titolo_validita_fine,
    v2.classif_tipo_desc AS classif_tipo_desc2, v2.classif_id AS tipologia_id,
    v2.classif_code AS tipologia_code, v2.classif_desc AS tipologia_desc,
    v2.validita_inizio AS tipologia_validita_inizio,
    v2.validita_fine AS tipologia_validita_fine,
    v1.classif_tipo_desc AS classif_tipo_desc3, v1.classif_id AS categoria_id,
    v1.classif_code AS categoria_code, v1.classif_desc AS categoria_desc,
    v1.validita_inizio AS categoria_validita_inizio,
    v1.validita_fine AS categoria_validita_fine, v1.ente_proprietario_id
FROM (SELECT tb.classif_classif_fam_tree_id, tb.classif_fam_tree_id, t1.classif_code,
    t1.classif_desc, ti1.classif_tipo_desc, tb.classif_id, tb.classif_id_padre,
    tb.ente_proprietario_id, tb.ordine, tb.level, tb.validita_inizio,
    tb.validita_fine
FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
    classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, validita_inizio, validita_fine, level, arrhierarchy) AS (
    SELECT rt1.classif_classif_fam_tree_id,
                            rt1.classif_fam_tree_id, rt1.classif_id,
                            rt1.classif_id_padre, rt1.ente_proprietario_id,
                            rt1.ordine, rt1.livello, tt1.validita_inizio,
                            tt1.validita_fine, 1,
                            ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
    FROM siac_r_class_fam_tree rt1,
                            siac_t_class_fam_tree tt1, siac_d_class_fam cf
    WHERE cf.classif_fam_id = tt1.classif_fam_id AND tt1.classif_fam_tree_id =
        rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_desc::text = 'Entrata - TitoliTipologieCategorie'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id
    UNION ALL
    SELECT tn.classif_classif_fam_tree_id,
                            tn.classif_fam_tree_id, tn.classif_id,
                            tn.classif_id_padre, tn.ente_proprietario_id,
                            tn.ordine, tn.livello, tn.validita_inizio,
                            tn.validita_fine, tp.level + 1,
                            tp.arrhierarchy || tn.classif_id
    FROM rqname tp, siac_r_class_fam_tree tn
    WHERE tp.classif_id = tn.classif_id_padre AND tn.ente_proprietario_id =
        tp.ente_proprietario_id
    )
    SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
            rqname.classif_id, rqname.classif_id_padre,
            rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
            rqname.validita_inizio, rqname.validita_fine, rqname.level
    FROM rqname
    ORDER BY rqname.arrhierarchy
    ) tb, siac_t_class t1,
    siac_d_class_tipo ti1
WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id =
    t1.classif_tipo_id AND t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND ti1.ente_proprietario_id = t1.ente_proprietario_id) v1,
-------------siac_v_tit_tip_cat_anni v1,
(SELECT tb.classif_classif_fam_tree_id, tb.classif_fam_tree_id, t1.classif_code,
    t1.classif_desc, ti1.classif_tipo_desc, tb.classif_id, tb.classif_id_padre,
    tb.ente_proprietario_id, tb.ordine, tb.level, tb.validita_inizio,
    tb.validita_fine
FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
    classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, validita_inizio, validita_fine, level, arrhierarchy) AS (
    SELECT rt1.classif_classif_fam_tree_id,
                            rt1.classif_fam_tree_id, rt1.classif_id,
                            rt1.classif_id_padre, rt1.ente_proprietario_id,
                            rt1.ordine, rt1.livello, tt1.validita_inizio,
                            tt1.validita_fine, 1,
                            ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
    FROM siac_r_class_fam_tree rt1,
                            siac_t_class_fam_tree tt1, siac_d_class_fam cf
    WHERE cf.classif_fam_id = tt1.classif_fam_id AND tt1.classif_fam_tree_id =
        rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_desc::text = 'Entrata - TitoliTipologieCategorie'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id
    UNION ALL
    SELECT tn.classif_classif_fam_tree_id,
                            tn.classif_fam_tree_id, tn.classif_id,
                            tn.classif_id_padre, tn.ente_proprietario_id,
                            tn.ordine, tn.livello, tn.validita_inizio,
                            tn.validita_fine, tp.level + 1,
                            tp.arrhierarchy || tn.classif_id
    FROM rqname tp, siac_r_class_fam_tree tn
    WHERE tp.classif_id = tn.classif_id_padre AND tn.ente_proprietario_id =
        tp.ente_proprietario_id
    )
    SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
            rqname.classif_id, rqname.classif_id_padre,
            rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
            rqname.validita_inizio, rqname.validita_fine, rqname.level
    FROM rqname
    ORDER BY rqname.arrhierarchy
    ) tb, siac_t_class t1,
    siac_d_class_tipo ti1
WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id =
    t1.classif_tipo_id AND t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND ti1.ente_proprietario_id = t1.ente_proprietario_id) v2, 
----------siac_v_tit_tip_cat_anni v2,
(SELECT tb.classif_classif_fam_tree_id, tb.classif_fam_tree_id, t1.classif_code,
    t1.classif_desc, ti1.classif_tipo_desc, tb.classif_id, tb.classif_id_padre,
    tb.ente_proprietario_id, tb.ordine, tb.level, tb.validita_inizio,
    tb.validita_fine
FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
    classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, validita_inizio, validita_fine, level, arrhierarchy) AS (
    SELECT rt1.classif_classif_fam_tree_id,
                            rt1.classif_fam_tree_id, rt1.classif_id,
                            rt1.classif_id_padre, rt1.ente_proprietario_id,
                            rt1.ordine, rt1.livello, tt1.validita_inizio,
                            tt1.validita_fine, 1,
                            ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
    FROM siac_r_class_fam_tree rt1,
                            siac_t_class_fam_tree tt1, siac_d_class_fam cf
    WHERE cf.classif_fam_id = tt1.classif_fam_id AND tt1.classif_fam_tree_id =
        rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_desc::text = 'Entrata - TitoliTipologieCategorie'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id
    UNION ALL
    SELECT tn.classif_classif_fam_tree_id,
                            tn.classif_fam_tree_id, tn.classif_id,
                            tn.classif_id_padre, tn.ente_proprietario_id,
                            tn.ordine, tn.livello, tn.validita_inizio,
                            tn.validita_fine, tp.level + 1,
                            tp.arrhierarchy || tn.classif_id
    FROM rqname tp, siac_r_class_fam_tree tn
    WHERE tp.classif_id = tn.classif_id_padre AND tn.ente_proprietario_id =
        tp.ente_proprietario_id
    )
    SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
            rqname.classif_id, rqname.classif_id_padre,
            rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
            rqname.validita_inizio, rqname.validita_fine, rqname.level
    FROM rqname
    ORDER BY rqname.arrhierarchy
    ) tb, siac_t_class t1,
    siac_d_class_tipo ti1
WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id =
    t1.classif_tipo_id AND t1.ente_proprietario_id = tb.ente_proprietario_id
     AND ti1.ente_proprietario_id = t1.ente_proprietario_id) v3
---------------    siac_v_tit_tip_cat_anni v3
WHERE v1.classif_id_padre = v2.classif_id AND v1.classif_tipo_desc::text =
    'Categoria'::text AND v2.classif_tipo_desc::text = 'Tipologia'::text 
    AND v2.classif_id_padre = v3.classif_id AND v3.classif_tipo_desc::text = 'Titolo Entrata'::text 
    AND v1.ente_proprietario_id = v2.ente_proprietario_id AND v2.ente_proprietario_id = v3.ente_proprietario_id) v
---------siac_v_tit_tip_cat_riga_anni 
where v.ente_proprietario_id=p_ente_prop_id 
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between v.categoria_validita_inizio and
COALESCE(v.categoria_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between v.tipologia_validita_inizio and
COALESCE(v.tipologia_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between v.titolo_validita_inizio and
COALESCE(v.titolo_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
order by titolo_code, tipologia_code,categoria_code;
*/

--06/09/2016: cambiata la query che carica la struttura di bilancio
--  per motivi prestazionali
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
where ct.classif_tipo_code			=	'CATEGORIA'
and ct.classif_tipo_id				=	cl.classif_tipo_id
and cl.classif_id					=	rc.classif_id 
and e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
and e.elem_id						=	rc.elem_id 
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	stato_capitolo.elem_stato_code	=	'VA'
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
--and	cat_del_capitolo.elem_cat_code	=	'STD'
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

--09/05/2016: carico nella tabella di appoggio con i capitoli gli eventuali 
-- capitoli presenti sulla tabella con gli importi previsti anni precedenti
-- che possono avere cambiato numero di capitolo. 
/*insert into siac_rep_cap_ep
      select t_class.classif_id, p_anno, NULL, prec.elem_code, prec.elem_code2, 
      	prec.elem_code3, NULL, NULL,  NULL, NULL, NULL, NULL, NULL,NULL,NULL,
        prec.ente_proprietario_id, prec.data_creazione, prec.data_modifica,
        prec.data_cancellazione,prec.login_operazione, user_table utente
      from siac_t_cap_e_importi_anno_prec prec,
        siac_d_class_tipo classif_tipo,
        siac_t_class t_class
      where classif_tipo.classif_tipo_id	=	t_class.classif_tipo_id
      and t_class.classif_code=prec.categoria_code
      and classif_tipo.classif_tipo_code	=	'CATEGORIA'
      and t_class.ente_proprietario_id =prec.ente_proprietario_id
      and t_class.ente_proprietario_id=p_ente_prop_id
      and to_timestamp('01/01/'||annoPrec,'dd/mm/yyyy')
		between t_class.validita_inizio and
        COALESCE(t_class.validita_fine, to_timestamp('31/12/'||annoPrec,'dd/mm/yyyy'))
      and not exists (select 1 from siac_rep_cap_ep ep
      				where ep.elem_code=prec.elem_code
                    	AND ep.elem_code2=prec.elem_code2
                        and ep.elem_code3=prec.elem_code3
                        and ep.classif_id = t_class.classif_id
                        and ep.utente=user_table
                        and ep.ente_proprietario_id=p_ente_prop_id);*/

-- REMEDY INC000001514672
-- Select ricostruita considerando la condizione sull'anno nella tabella siac_t_cap_e_importi_anno_prec                 
insert into siac_rep_cap_ep             
with prec as (       
select * From siac_t_cap_e_importi_anno_prec a
where a.anno=annoPrec       
and a.ente_proprietario_id=p_ente_prop_id
)
, categ as (
select * from siac_t_class a, siac_d_class_tipo b
where a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code = 'CATEGORIA'
and a.data_cancellazione is null
and b.data_cancellazione is null
and a.ente_proprietario_id=p_ente_prop_id
and to_timestamp('01/01/'||annoPrec,'dd/mm/yyyy') between
a.validita_inizio and COALESCE(a.validita_fine, to_timestamp('31/12/'||annoPrec,'dd/mm/yyyy'))
)  
select categ.classif_id classif_id_categ,  p_anno,
NULL, prec.elem_code, prec.elem_code2,
       prec.elem_code3, NULL, NULL,  NULL, NULL, NULL, NULL, NULL,NULL,NULL,
        prec.ente_proprietario_id, prec.data_creazione, prec.data_modifica,
        prec.data_cancellazione,prec.login_operazione, user_table utente
 from prec
join categ on prec.categoria_code=categ.classif_code
and not exists (select 1 from siac_rep_cap_ep ep
                      where ep.elem_code=prec.elem_code
                        AND ep.elem_code2=prec.elem_code2
                        and ep.elem_code3=prec.elem_code3
                        and ep.classif_id = categ.classif_id
                        and ep.utente=user_table
                        and ep.ente_proprietario_id=p_ente_prop_id);                        
  
--------------



insert into siac_rep_cap_ep_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	------coalesce (sum(capitolo_importi.elem_det_importo),0)    
            sum(capitolo_importi.elem_det_importo)   
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
        and	anno_eserc.anno						= 	p_anno 												
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code		=	'STD'
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
    group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;


insert into siac_rep_cap_ep_imp_riga
select  tb1.elem_id, 
  		coalesce (tb1.importo,0)   as 		stanziamento_prev_anno,
        coalesce (tb2.importo,0)   as 		stanziamento_prev_anno1,
        coalesce (tb3.importo,0)   as 		stanziamento_prev_anno2,
        coalesce (tb4.importo,0)   as 		residui_presunti,
        coalesce (tb5.importo,0)   as 		previsioni_anno_prec,
        coalesce (tb6.importo,0)   as 		stanziamento_prev_cassa_anno,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_ep_imp tb1, siac_rep_cap_ep_imp tb2, siac_rep_cap_ep_imp tb3,
	siac_rep_cap_ep_imp tb4, siac_rep_cap_ep_imp tb5, siac_rep_cap_ep_imp tb6
	where			tb1.elem_id	=	tb2.elem_id								and	
        			tb2.elem_id	=	tb3.elem_id								and
        			tb3.elem_id	=	tb4.elem_id								and
        			tb4.elem_id	=	tb5.elem_id								and
        			tb5.elem_id	=	tb6.elem_id								and
        			tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp	AND
        			tb2.periodo_anno = annoCapImp1	AND	tb1.tipo_imp =	tb2.tipo_imp	AND
        			tb3.periodo_anno = annoCapImp2	AND	tb2.tipo_imp =	tb3.tipo_imp	AND
        			tb4.periodo_anno = tb1.periodo_anno	AND	tb4.tipo_imp = 	TipoImpresidui	AND
        			tb5.periodo_anno = tb1.periodo_anno	AND	tb5.tipo_imp = 	TipoImpstanzresidui	AND
        			tb6.periodo_anno = tb1.periodo_anno	AND	tb6.tipo_imp = 	TipoImpCassa
                    and tb1.utente 	= 	tb2.utente	
        			and	tb2.utente	=	tb3.utente
        			and	tb3.utente	=	tb4.utente
        			and	tb4.utente	=	tb5.utente
        			and tb5.utente	=	tb6.utente
        			and	tb6.utente	=	user_table;
--------raise notice 'dopo insert siac_rep_cap_ep_imp_riga' ;                    


-------------------------------------
--22/07/2016:
--se sono state specificate delle variazioni cerco i relativi valori
/*22/09/2017: aggiunto anche il controllo relativo ai parametri degli atti.
	Nelle variabili contaParVarPeg e contaParVarBil sono contenuti il numero di parametri 
	riguardanti le delibere PEG e Bilancio; se sono 3 (numero, anno e tipo) significa
    che quel parametro e' stato passato e quindi devo aggiungere il filtro. 
    Aggiunto anche il controllo relativo alle direzione e settori.
    Se p_code_sac_direz_peg e p_code_sac_direz_bil sono uguali a 999 significa che NON
    sono stati specificati. */
--IF ele_variazioni IS NOT NULL AND ele_variazioni <> '' THEN    
IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') OR
	 contaParVarPeg= 3 OR contaParVarBil = 3 OR p_code_sac_direz_peg <> '999' OR
     p_code_sac_direz_bil <> '999' THEN
	sql_query='
    insert into siac_rep_var_entrate
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),
            tipo_elemento.elem_det_tipo_code,  ';
    sql_query=sql_query || ' '''||user_table||''' utente, '; 
    sql_query=sql_query || ' testata_variazione.ente_proprietario_id	,
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
            siac_t_periodo              anno_importo,
            siac_t_bil                  bilancio ';            
    if contaParVarPeg = 3 then 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto ,
            siac_d_atto_amm_tipo		tipo_atto,
			siac_r_atto_amm_stato 		r_atto_stato,
	        siac_d_atto_amm_stato 		stato_atto ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto2 ,
            siac_d_atto_amm_tipo		tipo_atto2,
			siac_r_atto_amm_stato 		r_atto_stato2,
	        siac_d_atto_amm_stato 		stato_atto2 ';
    end if;
    IF p_code_sac_direz_peg <> '999'  THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti'; 
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti2'; 
    END IF;
    sql_query=sql_query||' where 	r_variazione_stato.variazione_id =	testata_variazione.variazione_id
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
    if contaParVarPeg = 3 then 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id						=	atto.attoamm_id
    	and		atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
    	and 	atto.attoamm_id										= 	r_atto_stato.attoamm_id
    	and 	r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id_varbil				=	atto2.attoamm_id
    	and		atto2.attoamm_tipo_id								=	tipo_atto2.attoamm_tipo_id
    	and 	atto2.attoamm_id									= 	r_atto_stato2.attoamm_id
    	and 	r_atto_stato2.attoamm_stato_id						=	stato_atto2.attoamm_stato_id ';
    end if;
        
    IF p_code_sac_direz_peg <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id =ele_dir_sett_atti.attoamm_id ';
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id_varbil =ele_dir_sett_atti2.attoamm_id ';
    END IF;
    sql_query=sql_query||' and		testata_variazione.ente_proprietario_id				= ' || p_ente_prop_id;
    sql_query=sql_query || ' and		anno_eserc.anno			= 	'''||p_anno||'''
    and		tipologia_stato_var.variazione_stato_tipo_code in (''B'',''G'', ''C'', ''P'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCode|| '''    
    and		tipo_elemento.elem_det_tipo_code	in (''STA'',''SCA'',''STR'') ';
    IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
    	sql_query=sql_query || ' and testata_variazione.variazione_num in ('||p_ele_variazioni||') ';
    end if;
    if contaParVarPeg = 3 then 
    	sql_query=sql_query||' AND stato_atto.attoamm_stato_code <> ''ANNULLATO'' 
        and 	atto.attoamm_numero ='||p_num_provv_var_peg||' 
    	and 	atto.attoamm_anno ='''||p_anno_provv_var_peg||'''
    	and		tipo_atto.attoamm_tipo_code='''||p_tipo_provv_var_peg||''' ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||' AND stato_atto2.attoamm_stato_code <> ''ANNULLATO'' 
        and 	atto2.attoamm_numero ='||p_num_provv_var_bil||' 
    	and 	atto2.attoamm_anno ='''||p_anno_provv_var_bil||'''
    	and		tipo_atto2.attoamm_tipo_code='''||p_tipo_provv_var_bil||''' ';
    end if;
    IF p_code_sac_direz_peg <> '999' THEN
    	IF p_code_sac_sett_peg = 'T' THEN  -- qualunque settore.
    		sql_query=sql_query||'
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' ';
        ELSIF p_code_sac_sett_peg = '999' THEN -- settore non specificato, quindi atto legato solo ad una direzione.
        	sql_query=sql_query||'
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' 
        		and ele_dir_sett_atti.cod_sett ='''' ';
        ELSE sql_query=sql_query||'    -- = specificati un settore.
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' 
        		and ele_dir_sett_atti.cod_sett ='''||p_code_sac_sett_peg||'''';
        END IF;
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	IF p_code_sac_sett_bil = 'T' THEN  -- qualunque settore.
    		sql_query=sql_query||'
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' ';
        ELSIF p_code_sac_sett_bil = '999' THEN -- settore non specificato, quindi atto legato solo ad una direzione.
        	sql_query=sql_query||'
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' 
        		and ele_dir_sett_atti2.cod_sett ='''' ';
        ELSE sql_query=sql_query||'    -- = specificato un settore.
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' 
        		and ele_dir_sett_atti2.cod_sett ='''||p_code_sac_sett_bil||'''';
        END IF;
    END IF;
    sql_query=sql_query || ' and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null ';
 
    if contaParVarPeg = 3 then 
    	sql_query=sql_query || ' and 	atto.data_cancellazione						is null
    	and 	tipo_atto.data_cancellazione				is null
    	and 	r_atto_stato.data_cancellazione				is null ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query || ' and 	atto2.data_cancellazione		is null
    	and 	tipo_atto2.data_cancellazione				is null
    	and 	r_atto_stato2.data_cancellazione			is null ';
    end if;
    sql_query=sql_query || ' group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                testata_variazione.ente_proprietario_id,
                anno_importo.anno';	     
         
raise notice 'Query: % ',  sql_query;      
EXECUTE sql_query;

RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  

    insert into siac_rep_var_entrate_riga
    select  tb0.elem_id,     
            tb1.importo   as 		variazione_aumento_stanziato,
            tb2.importo   as 		variazione_diminuzione_stanziato,
            tb3.importo   as 		variazione_aumento_cassa,
            tb4.importo   as 		variazione_diminuzione_cassa,
            tb5.importo   as 		variazione_aumento_residuo,
            tb6.importo   as 		variazione_diminuzione_residuo,
            user_table utente,
            p_ente_prop_id,
            p_anno
    from   
        siac_rep_cap_ep tb0 
        left join siac_rep_var_entrate tb1
         on (tb1.elem_id		=	tb0.elem_id	
            and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
            and tb1.periodo_anno=p_anno
            and tb1.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb2
        on (tb2.elem_id		=	tb0.elem_id
            and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
            and tb2.periodo_anno=p_anno
            and tb2.utente = tb0.utente )
        left join siac_rep_var_entrate tb3
         on (tb3.elem_id		=	tb0.elem_id	
            and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
            and tb3.periodo_anno=p_anno
            and tb3.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb4
        on (tb4.elem_id		=	tb0.elem_id
            and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
            and tb4.periodo_anno=p_anno
            and tb4.utente = tb0.utente )
        left join siac_rep_var_entrate tb5
         on (tb5.elem_id		=	tb0.elem_id	
            and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
            and tb5.periodo_anno=p_anno
            and tb5.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb6
        on (tb6.elem_id		=	tb0.elem_id
            and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
            and tb6.periodo_anno=p_anno
            and tb6.utente = tb0.utente 	)
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
            (p_anno::INTEGER + 1)::varchar
    from   
        siac_rep_cap_ep tb0 
        left join siac_rep_var_entrate tb1
         on (tb1.elem_id		=	tb0.elem_id	
            and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
            and tb1.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb1.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb2
        on (tb2.elem_id		=	tb0.elem_id
            and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
            and tb2.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb2.utente = tb0.utente )
        left join siac_rep_var_entrate tb3
         on (tb3.elem_id		=	tb0.elem_id	
            and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
            and tb3.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb3.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb4
        on (tb4.elem_id		=	tb0.elem_id
            and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
            and tb4.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb4.utente = tb0.utente )
        left join siac_rep_var_entrate tb5
         on (tb5.elem_id		=	tb0.elem_id	
            and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
            and tb5.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb5.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb6
        on (tb6.elem_id		=	tb0.elem_id
            and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
            and tb6.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb6.utente = tb0.utente 	)
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
            (p_anno::INTEGER + 2)::varchar
        from   
        siac_rep_cap_ep tb0 
        left join siac_rep_var_entrate tb1
         on (tb1.elem_id		=	tb0.elem_id	
            and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
            and tb1.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb1.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb2
        on (tb2.elem_id		=	tb0.elem_id
            and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
            and tb2.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb2.utente = tb0.utente )
        left join siac_rep_var_entrate tb3
         on (tb3.elem_id		=	tb0.elem_id	
            and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
            and tb3.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb3.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb4
        on (tb4.elem_id		=	tb0.elem_id
            and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
            and tb4.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb4.utente = tb0.utente )
        left join siac_rep_var_entrate tb5
         on (tb5.elem_id		=	tb0.elem_id	
            and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
            and tb5.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb5.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb6
        on (tb6.elem_id		=	tb0.elem_id
            and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
            and tb6.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb6.utente = tb0.utente 	);
end if;

-------------------------------------



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
       	tb.elem_desc2     				BIL_ELE_DESC2,
        tb.elem_code3					BIL_ELE_CODE3,
       	tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
	   	COALESCE (tb1.stanziamento_prev_anno,0)			stanziamento_prev_anno,
		COALESCE (tb1.stanziamento_prev_anno1,0)		stanziamento_prev_anno1,
    	COALESCE (tb1.stanziamento_prev_anno2,0)		stanziamento_prev_anno2,
   	 	COALESCE (tb1.residui_presunti,0)				residui_presunti,
    	COALESCE (tb1.previsioni_anno_prec,0)			previsioni_anno_prec,
    	COALESCE (tb1.stanziamento_prev_cassa_anno,0)	stanziamento_prev_cassa_anno,
        COALESCE (var_anno.variazione_aumento_cassa, 0)		variazione_aumento_cassa,
        COALESCE (var_anno.variazione_aumento_residuo, 0)	variazione_aumento_residuo,
        COALESCE (var_anno.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato,
        COALESCE (var_anno.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa,
        COALESCE (var_anno.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo,
        COALESCE (var_anno.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato,
        COALESCE (var_anno1.variazione_aumento_cassa, 0)		variazione_aumento_cassa1,
        COALESCE (var_anno1.variazione_aumento_residuo, 0)	variazione_aumento_residuo1,
        COALESCE (var_anno1.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato1,
        COALESCE (var_anno1.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa1,
        COALESCE (var_anno1.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo1,
        COALESCE (var_anno1.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato1,
        COALESCE (var_anno2.variazione_aumento_cassa, 0)		variazione_aumento_cassa2,
        COALESCE (var_anno2.variazione_aumento_residuo, 0)	variazione_aumento_residuo2,
        COALESCE (var_anno2.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato2,
        COALESCE (var_anno2.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa2,
        COALESCE (var_anno2.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo2,
        COALESCE (var_anno2.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato2
        
from  	siac_rep_tit_tip_cat_riga_anni v1
			FULL  join siac_rep_cap_ep tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					--and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
           --------RIGHT	join    siac_rep_cap_ep_imp_riga tb1  on tb1.elem_id	=	tb.elem_id 	
           left	join    siac_rep_cap_ep_imp_riga tb1  
           			on (tb1.elem_id	=	tb.elem_id
                    	and	tb.utente=user_table
                        and tb1.utente	=	tb.utente)
			left	join  siac_rep_var_entrate_riga var_anno
           			on (var_anno.elem_id	=	tb.elem_id
                    	and var_anno.periodo_anno= annoCapImp
                    	and	tb.utente=user_table
                        and var_anno.utente	=	tb.utente)         
			left	join  siac_rep_var_entrate_riga var_anno1
           			on (var_anno1.elem_id	=	tb.elem_id
                    	and var_anno1.periodo_anno= annoCapImp1
                    	and	tb.utente=user_table
                        and var_anno1.utente	=	tb.utente)  
			left	join  siac_rep_var_entrate_riga var_anno2
           			on (var_anno2.elem_id	=	tb.elem_id
                    	and var_anno2.periodo_anno= annoCapImp2
                    	and	tb.utente=user_table
                        and var_anno2.utente	=	tb.utente)                                                                        
    where v1.utente = user_table 	
			order by titoloe_CODE,tipologia_CODE,categoria_CODE            

loop



/*raise notice 'Dentro loop estrazione capitoli elem_id % ',classifBilRec.bil_ele_id;*/

-- dati capitolo

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
stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;
stanziamento_prev_cassa_anno:=classifBilRec.stanziamento_prev_cassa_anno;
residui_presunti:=classifBilRec.residui_presunti;
previsioni_anno_prec:=classifBilRec.previsioni_anno_prec;

previsioni_anno_prec_cassa:=0;
previsioni_anno_prec_comp:=0;

--25/07/2016: sommo gli eventuali valori delle variazioni
stanziamento_prev_anno=stanziamento_prev_anno+classifBilRec.variazione_aumento_stanziato+
            					    classifBilRec.variazione_diminuzione_stanziato;
stanziamento_prev_cassa_anno=stanziamento_prev_cassa_anno+classifBilRec.variazione_aumento_cassa+
            					    classifBilRec.variazione_diminuzione_cassa;                                    
stanziamento_prev_anno1=stanziamento_prev_anno1+classifBilRec.variazione_aumento_stanziato1+
            					    classifBilRec.variazione_diminuzione_stanziato1;
stanziamento_prev_anno2=stanziamento_prev_anno2+classifBilRec.variazione_aumento_stanziato2+
            					    classifBilRec.variazione_diminuzione_stanziato2;
residui_presunti=residui_presunti+classifBilRec.variazione_aumento_residuo+
            					    classifBilRec.variazione_diminuzione_residuo;
if classifBilRec.variazione_aumento_stanziato <> 0 OR
	classifBilRec.variazione_diminuzione_stanziato <> 0 OR
    classifBilRec.variazione_aumento_cassa <> 0 OR
    classifBilRec.variazione_diminuzione_cassa <> 0 OR    
    classifBilRec.variazione_aumento_stanziato1 <> 0 OR
    classifBilRec.variazione_diminuzione_stanziato1 <> 0 OR
    classifBilRec.variazione_aumento_stanziato2 <> 0 OR
    classifBilRec.variazione_diminuzione_stanziato2 <> 0 OR  
    classifBilRec.variazione_aumento_residuo <> 0 OR
    classifBilRec.variazione_diminuzione_residuo <> 0 THEN
raise notice 'Cap %, ID = %, Tipologia %', bil_ele_code, bil_ele_id, tipologia_code;
raise notice '  variazione_aumento_stanziato = %',classifBilRec.variazione_aumento_stanziato;
raise notice '  variazione_diminuzione_stanziato = %',classifBilRec.variazione_diminuzione_stanziato;
raise notice '  variazione_aumento_cassa = %',classifBilRec.variazione_aumento_cassa;
raise notice '  variazione_diminuzione_cassa = %',classifBilRec.variazione_diminuzione_cassa;
raise notice '  variazione_aumento_stanziato1 = %',classifBilRec.variazione_aumento_stanziato1;
raise notice '  variazione_diminuzione_stanziato1 = %',classifBilRec.variazione_diminuzione_stanziato1;
raise notice '  variazione_aumento_stanziato2 = %',classifBilRec.variazione_aumento_stanziato2;
raise notice '  variazione_diminuzione_stanziato2 = %',classifBilRec.variazione_diminuzione_stanziato2;
raise notice '  variazione_aumento_residuo = %',classifBilRec.variazione_aumento_residuo;
raise notice '  variazione_diminuzione_residuo = %',classifBilRec.variazione_diminuzione_residuo;

end if;    
    
--06/05/2016: cerco i dati relativi alle previsioni anno precedente.
IF classifBilRec.bil_ele_code IS NOT NULL THEN
	--raise notice 'Cerco: titolo_code=%, tipologia_code=%, categoria_code=%,  bil_ele_code=%, bil_ele_code2=%, bil_ele_code3= %, anno=%', classifBilRec.titoloe_CODE, classifBilRec.tipologia_code, classifBilRec.categoria_code,bil_ele_code,bil_ele_code2, classifBilRec.BIL_ELE_CODE3, annoPrec;
  SELECT COALESCE(imp_prev_anno_prec.importo_cassa,0) importo_cassa,
          COALESCE(imp_prev_anno_prec.importo_competenza, 0) importo_competenza
  INTO previsioni_anno_prec_cassa, previsioni_anno_prec_comp 
  FROM siac_t_cap_e_importi_anno_prec  imp_prev_anno_prec
  WHERE imp_prev_anno_prec.categoria_code=classifBilRec.categoria_code
      AND imp_prev_anno_prec.elem_code=classifBilRec.bil_ele_code
      AND imp_prev_anno_prec.elem_code2=classifBilRec.bil_ele_code2
      AND imp_prev_anno_prec.elem_code3=classifBilRec.BIL_ELE_CODE3
      AND imp_prev_anno_prec.anno= annoPrec
      AND imp_prev_anno_prec.ente_proprietario_id=p_ente_prop_id
      AND imp_prev_anno_prec.data_cancellazione IS NULL;
  IF NOT FOUND THEN 
      previsioni_anno_prec_comp=0;
      previsioni_anno_prec_cassa=0;
  END IF;
ELSE	
      previsioni_anno_prec_comp=0;
      previsioni_anno_prec_cassa=0;
END IF;
--raise notice 'previsioni_anno_prec_comp= %, previsioni_anno_prec_cassa=%', previsioni_anno_prec_comp,previsioni_anno_prec_cassa;
--06/05/2016: in prima battuta la tabella siac_t_cap_e_importi_anno_prec NON
-- conterra' i dati della competenza ma solo quelli della cassa, pertanto
-- il dato della competenza letto dalla tabella e' sostituito da quello che
-- era contenuto nel campo previsioni_anno_prec.
-- Quando sara' valorizzato la seguente riga dovra' ESSERE ELIMINATA!!!
--previsioni_anno_prec_comp=previsioni_anno_prec;


/*raise notice 'record';*/
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
previsioni_anno_prec:=0;
stanziamento_prev_cassa_anno:=0;

end loop;

delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;

delete from siac_rep_tit_tip_cat_riga where utente=user_table;

delete from siac_rep_cap_ep where utente=user_table;

delete from siac_rep_cap_ep_imp where utente=user_table;

delete from siac_rep_cap_ep_imp_riga where utente=user_table;

delete from siac_rep_var_entrate where utente=user_table;

delete from siac_rep_var_entrate_riga where utente=user_table;

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

CREATE OR REPLACE FUNCTION siac."BILR111_Allegato_9_bil_gest_spesa_mpt" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_disavanzo boolean,
  p_ele_variazioni varchar,
  p_num_provv_var_peg integer,
  p_anno_provv_var_peg varchar,
  p_tipo_provv_var_peg varchar,
  p_num_provv_var_bil integer,
  p_anno_provv_var_bil varchar,
  p_tipo_provv_var_bil varchar,
  p_code_sac_direz_peg varchar,
  p_code_sac_sett_peg varchar,
  p_code_sac_direz_bil varchar,
  p_code_sac_sett_bil varchar
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
  impegnato_anno numeric,
  impegnato_anno1 numeric,
  impegnato_anno2 numeric,
  stanziamento_fpv_anno_prec numeric,
  stanziamento_fpv_anno numeric,
  stanziamento_fpv_anno1 numeric,
  stanziamento_fpv_anno2 numeric,
  fase_bilancio varchar,
  capitolo_prec integer,
  bil_ele_code3 varchar,
  previsioni_anno_prec_comp numeric,
  previsioni_anno_prec_cassa numeric,
  display_error varchar
) AS
$body$
DECLARE

classifBilRec record;
ImpegniRec record;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
elemTipoCode_UG	varchar;
TipoImpstanzresidui varchar;
tipo_capitolo	varchar;
h_count integer :=0;
importo integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
tipologia_capitolo	varchar;
cat_capitolo	varchar;
esiste_siac_t_dicuiimpegnato_bilprev integer;
annoPrec VARCHAR;
annobilint integer :=0;
previsioni_anno_prec_cassa_app NUMERIC;
previsioni_anno_prec_comp_app NUMERIC;
tipo_categ_capitolo VARCHAR;
stanziamento_fpv_anno_prec_app NUMERIC;
sql_query VARCHAR;
strApp VARCHAR;
intApp INTEGER;
v_importo_imp   NUMERIC :=0;
v_importo_imp1  NUMERIC :=0;
v_importo_imp2  NUMERIC :=0;
v_conta_rec INTEGER :=0;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
-- ALESSANDRO - SIAC-5208 - oltre 4 variazioni, il codice si sfonda
x_array VARCHAR [];
-- ALESSANDRO - SIAC-5208 - FINE

contaParVarPeg integer;
contaParVarBil integer;

BEGIN

annobilint := p_anno::INTEGER;
annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
elemTipoCode:='CAP-UG'; -- tipo capitolo previsione
elemTipoCode_UG:='CAP-UG';	--- Capitolo gestione

annoPrec:=((p_anno::INTEGER)-1)::VARCHAR;
display_error='';
contaParVarPeg:=0;
contaParVarBil:=0;

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  -- ALESSANDRO - SIAC-5208 - non posso castare l'intera stringa a integer: spezzo e parsifico pezzo a pezzo
  x_array = string_to_array(p_ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    --strApp=REPLACE(p_ele_variazioni,',','');
    --raise notice 'VAR: %', strApp;
    intApp = strApp::INTEGER;
  END LOOP;
  -- ALESSANDRO - SIAC-5208 - FINE
END IF;

/* 25/09/2017: parametri nuovi, controllo che se e' passato uno tra numero/anno/tipo
    	provvedimento di variazione di PEG o di BILANCIO, siano passati anche
        gli altri 2. */
if p_num_provv_var_peg IS NOT  NULL THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if p_anno_provv_var_peg IS NOT  NULL AND p_anno_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if p_tipo_provv_var_peg IS NOT  NULL AND p_tipo_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if contaParVarPeg not in (0,3) then
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di PEG''';
    return next;
    return;        
end if;

if p_num_provv_var_bil IS NOT  NULL THEN
	contaParVarBil=contaParVarBil+1;
end if;
if p_anno_provv_var_bil IS NOT  NULL AND p_anno_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
end if;
if p_tipo_provv_var_bil IS NOT  NULL AND p_tipo_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
end if;
if contaParVarBil not in (0,3) then
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di Bilancio''';
    return next;
    return;        
end if;

select fnc_siac_random_user()
into	user_table;

raise notice '1: %', clock_timestamp()::varchar;  
-- raise notice 'user  %',user_table;

/* 06/09/2016: eliminata lettura fase di bilancio perche' NON necessaria.
begin
     RTN_MESSAGGIO:='lettura anno di bilancio''.';  
for classifBilRec in
select 	anno_eserc.anno BIL_ANNO, 
        r_fase.bil_fase_operativa_id, 
        fase.fase_operativa_desc, 
        fase.fase_operativa_code fase_bilancio
from 	siac_t_bil 						bilancio,
		siac_t_periodo 					anno_eserc,
        siac_d_periodo_tipo				tipo_periodo,
        siac_r_bil_fase_operativa 		r_fase,
        siac_d_fase_operativa  			fase
where	anno_eserc.anno						=	p_anno							and	
		bilancio.periodo_id					=	anno_eserc.periodo_id			and
        tipo_periodo.periodo_tipo_code		=	'SY'							and
        anno_eserc.ente_proprietario_id		=	p_ente_prop_id					and
        tipo_periodo.periodo_tipo_id		=	anno_eserc.periodo_tipo_id		and
        r_fase.bil_id						=	bilancio.bil_id					AND
        r_fase.fase_operativa_id			=	fase.fase_operativa_id			and
        bilancio.data_cancellazione			is null								and							
		anno_eserc.data_cancellazione		is null								and	
        tipo_periodo.data_cancellazione		is null								and	
       	r_fase.data_cancellazione			is null								and	
        fase.data_cancellazione				is null								and
        now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())			and		
        now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())		and
        now() between tipo_periodo.validita_inizio and coalesce (tipo_periodo.validita_fine, now())	and        
        now() between r_fase.validita_inizio and coalesce (r_fase.validita_fine, now())				and
		now() between fase.validita_inizio and coalesce (fase.validita_fine, now())

loop
   fase_bilancio:=classifBilRec.fase_bilancio;
--raise notice 'Fase bilancio  %',classifBilRec.fase_bilancio;

anno_bil_impegni:=p_anno;

  if classifBilRec.fase_bilancio = 'P'  then
      anno_bil_impegni:= ((p_anno::INTEGER)-1)::VARCHAR;
  else
      anno_bil_impegni:=p_anno;
  end if;
end loop;

exception
	when no_data_found THEN
		raise notice 'Fase del bilancio non trovata';
	return;
	when others  THEN
        RTN_MESSAGGIO:='errore ricerca fase bilancio';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
       return;
end; */

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
impegnato_anno=0;
impegnato_anno1=0;
impegnato_anno2=0;
stanziamento_fpv_anno_prec=0;
stanziamento_fpv_anno=0;
stanziamento_fpv_anno1=0;
stanziamento_fpv_anno2=0;
tipologia_capitolo='';
previsioni_anno_prec_comp=0;
previsioni_anno_prec_cassa=0;
stanziamento_fpv_anno_prec=0;
      
     RTN_MESSAGGIO:='lettura struttura del bilancio''.';  
raise notice '2: %', clock_timestamp()::varchar;  
/* insert into siac_rep_mis_pro_tit_mac_riga_anni
select v.*,user_table from
(SELECT missione_tipo.classif_tipo_desc AS missione_tipo_desc,
    missione.classif_id AS missione_id, missione.classif_code AS missione_code,
    missione.classif_desc AS missione_desc,
    missione.validita_inizio AS missione_validita_inizio,
    missione.validita_fine AS missione_validita_fine,
    programma_tipo.classif_tipo_desc AS programma_tipo_desc,
    programma.classif_id AS programma_id,
    programma.classif_code AS programma_code,
    programma.classif_desc AS programma_desc,
    programma.validita_inizio AS programma_validita_inizio,
    programma.validita_fine AS programma_validita_fine,
    titusc_tipo.classif_tipo_desc AS titusc_tipo_desc,
    titusc.classif_id AS titusc_id, titusc.classif_code AS titusc_code,
    titusc.classif_desc AS titusc_desc,
    titusc.validita_inizio AS titusc_validita_inizio,
    titusc.validita_fine AS titusc_validita_fine,
    macroaggr_tipo.classif_tipo_desc AS macroag_tipo_desc,
    macroaggr.classif_id AS macroag_id, macroaggr.classif_code AS macroag_code,
    macroaggr.classif_desc AS macroag_desc,
    macroaggr.validita_inizio AS macroag_validita_inizio,
    macroaggr.validita_fine AS macroag_validita_fine,
    macroaggr.ente_proprietario_id
FROM siac_d_class_fam missione_fam, siac_t_class_fam_tree missione_tree,
    siac_r_class_fam_tree missione_r_cft, siac_t_class missione,
    siac_d_class_tipo missione_tipo, siac_d_class_tipo programma_tipo,
    siac_t_class programma, siac_d_class_fam titusc_fam,
    siac_t_class_fam_tree titusc_tree, siac_r_class_fam_tree titusc_r_cft,
    siac_t_class titusc, siac_d_class_tipo titusc_tipo,
    siac_d_class_tipo macroaggr_tipo, siac_t_class macroaggr
WHERE missione_fam.classif_fam_desc::text = 'Spesa - MissioniProgrammi'::text
    AND missione_fam.classif_fam_id = missione_tree.classif_fam_id 
    AND missione_tree.classif_fam_tree_id = missione_r_cft.classif_fam_tree_id 
    AND missione_r_cft.classif_id_padre = missione.classif_id 
    AND missione.classif_tipo_id = missione_tipo.classif_tipo_id 
    AND missione_tipo.classif_tipo_code::text = 'MISSIONE'::text 
    AND programma_tipo.classif_tipo_code::text = 'PROGRAMMA'::text 
    AND missione_r_cft.classif_id = programma.classif_id 
    AND programma.classif_tipo_id = programma_tipo.classif_tipo_id 
    AND titusc_fam.classif_fam_desc::text = 'Spesa - TitoliMacroaggregati'::text 
    AND titusc_fam.classif_fam_id = titusc_tree.classif_fam_id 
    AND titusc_tree.classif_fam_tree_id = titusc_r_cft.classif_fam_tree_id 
    AND titusc_r_cft.classif_id_padre = titusc.classif_id 
    AND titusc_tipo.classif_tipo_code::text = 'TITOLO_SPESA'::text 
    AND titusc.classif_tipo_id = titusc_tipo.classif_tipo_id 
    AND macroaggr_tipo.classif_tipo_code::text = 'MACROAGGREGATO'::text 
    AND titusc_r_cft.classif_id = macroaggr.classif_id 
    AND macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id 
    AND missione.ente_proprietario_id = programma.ente_proprietario_id 
    AND programma.ente_proprietario_id = titusc.ente_proprietario_id 
    AND titusc.ente_proprietario_id = macroaggr.ente_proprietario_id
ORDER BY missione.classif_code, programma.classif_code, titusc.classif_code,
    macroaggr.classif_code) v
--------siac_v_mis_pro_tit_macr_anni 
 where v.ente_proprietario_id=p_ente_prop_id 
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.macroag_validita_inizio and
COALESCE(v.macroag_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.missione_validita_inizio and
COALESCE(v.missione_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.programma_validita_inizio and
COALESCE(v.programma_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.titusc_validita_inizio and
COALESCE(v.titusc_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
order by missione_code, programma_code,titusc_code,macroag_code;
*/

-- 06/09/2016: sostituita la query di caricamento struttura del bilancio
--   per migliorare prestazioni
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

raise notice '3: %', clock_timestamp()::varchar; 
     RTN_MESSAGGIO:='insert tabella siac_rep_cap_up''.';  
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
    capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
	stato_capitolo.elem_stato_code	=	'VA'								and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and
    ---------and	cat_del_capitolo.elem_cat_code	=	'STD'	
    -- 06/09/2016: aggiunto FPVC
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
    and	r_cat_capitolo.data_cancellazione 	 		is null;	


--09/05/2016: carico nella tabella di appoggio con i capitoli gli eventuali 
-- capitoli presenti sulla tabella con gli importi previsti anni precedenti
-- che possono avere cambiato numero di capitolo. 
/*insert into siac_rep_cap_up 
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
                        and up.ente_proprietario_id=p_ente_prop_id);*/

-- REMEDY INC000001514672
-- Select ricostruita considerando la condizione sull'anno nella tabella siac_t_cap_u_importi_anno_prec                        
insert into siac_rep_cap_up                        
with prec as (       
select * From siac_t_cap_u_importi_anno_prec a
where a.anno=annoPrec       
and a.ente_proprietario_id=p_ente_prop_id
)
, progr as (
select * from siac_t_class a, siac_d_class_tipo b
where a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code = 'PROGRAMMA'
and a.data_cancellazione is null
and b.data_cancellazione is null
and a.ente_proprietario_id=p_ente_prop_id
and to_timestamp('01/01/'||annoPrec,'dd/mm/yyyy') between
a.validita_inizio and COALESCE(a.validita_fine, to_timestamp('31/12/'||annoPrec,'dd/mm/yyyy'))
)
, macro as (
select * from siac_t_class a, siac_d_class_tipo b
where a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code = 'MACROAGGREGATO'
and a.data_cancellazione is null
and b.data_cancellazione is null
and a.ente_proprietario_id=p_ente_prop_id
and to_timestamp('01/01/'||annoPrec,'dd/mm/yyyy') between
a.validita_inizio and COALESCE(a.validita_fine, to_timestamp('31/12/'||annoPrec,'dd/mm/yyyy'))
)
select progr.classif_id classif_id_programma, macro.classif_id classif_id_macroaggregato, p_anno,
NULL, prec.elem_code, prec.elem_code2,
       prec.elem_code3, NULL, NULL,  NULL, NULL, NULL, NULL, NULL,NULL,NULL,
        prec.ente_proprietario_id, prec.data_creazione, prec.data_modifica,
        prec.data_cancellazione,prec.login_operazione, NULL, user_table utente
 from prec
join progr on prec.programma_code=progr.classif_code
join macro on prec.macroagg_code=macro.classif_code
and not exists (select 1 from siac_rep_cap_up up
                      where up.elem_code=prec.elem_code
                        AND up.elem_code2=prec.elem_code2
                        and up.elem_code3=prec.elem_code3
                        and up.macroaggregato_id = macro.classif_id
                        and up.programma_id = progr.classif_id
                        and up.utente=user_table
                        and up.ente_proprietario_id=prec.ente_proprietario_id);
                    
-----------------   importo capitoli di tipo standard ------------------------

     RTN_MESSAGGIO:='insert tabella siac_rep_cap_up_imp standard''.';  
raise notice '4: %', clock_timestamp()::varchar; 
insert into siac_rep_cap_up_imp 
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo),
       		cat_del_capitolo.elem_cat_code tipologia_capitolo       
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,
            siac_t_bil_elem 			capitolo,
            siac_d_bil_elem_tipo 		tipo_elemento,
            siac_t_bil 					bilancio,
	 		siac_t_periodo 				anno_eserc, 
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
        and	anno_eserc.anno					= p_anno 												
    	and	bilancio.periodo_id				=anno_eserc.periodo_id 								
        and	capitolo.bil_id					=bilancio.bil_id 			 
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
        -- 06/09/2016: aggiunto FPV (che era in query successiva che 
        -- e' stata tolta) e FPVC
		and	cat_del_capitolo.elem_cat_code	in ('STD','FSC','FPV','FPVC')						
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

-----------------   importo capitoli di tipo fondo pluriennale vincolato ------------------------
  
-----------------------------------------------------------------------------------------------
     RTN_MESSAGGIO:='insert tabella siac_rep_cap_up_imp_riga STD''.';  


raise notice '5: %', clock_timestamp()::varchar; 
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
        user_table utente from 
        siac_rep_cap_up_imp tb1, siac_rep_cap_up_imp tb2, siac_rep_cap_up_imp tb3,
		siac_rep_cap_up_imp tb4, siac_rep_cap_up_imp tb5, siac_rep_cap_up_imp tb6
         where			
    	tb1.elem_id	=	tb2.elem_id
        and 
        tb2.elem_id	=	tb3.elem_id
        and 
        tb3.elem_id	=	tb4.elem_id
        and 
        tb4.elem_id	=	tb5.elem_id
        and 
        tb5.elem_id	=	tb6.elem_id
        and
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

raise notice '6: %', clock_timestamp()::varchar; 
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
        AND -- 06/09/2016: aggiunto FPVC
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

-----------------------------------------------------------------------------------
raise notice '7: %', clock_timestamp()::varchar; 
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
					AND v1.utente=user_table
                    and	TB.utente=V1.utente)
            left	join    siac_rep_cap_up_imp_riga tb1  
            		on (tb1.elem_id	=	tb.elem_id
                    	and	tb.utente=user_table
                        and tb1.utente	=	tb.utente)
            left JOIN siac_r_bil_elem_rel_tempo tbprec ON tbprec.elem_id = tb.elem_id and tbprec.data_cancellazione is null
    where v1.utente = user_table
    		------and TB.utente=V1.utente
            ------and	tb1.utente	=	tb.utente
           order by missione_code,programma_code,titusc_code,macroag_code,	BIL_ELE_ID;

raise notice '7.1: %', clock_timestamp()::varchar; 
/*
 if classifBilRec.fase_bilancio = 'P'  then
 	tipo_capitolo:=elemTipoCode_UG;
 else
 	tipo_capitolo:=elemTipoCode;
 end if;
 */
 
 tipo_capitolo:=elemTipoCode_UG;
 
 
 -------------------------------------
--25/07/2016:
--se sono state specificate delle variazioni cerco i relativi valori
/*25/09/2017: aggiunto anche il controllo relativo ai parametri degli atti.
	Nelle variabili contaParVarPeg e contaParVarBil sono contenuti il numero di parametri 
	riguardanti le delibere PEG e Bilancio; se sono 3 (numero, anno e tipo) significa
    che quel parametro e' stato passato e quindi devo aggiungere il filtro. 
    Aggiunto anche il controllo relativo alle direzione e settori.
    Se p_code_sac_direz_peg e p_code_sac_direz_bil sono uguali a 999 significa che NON
    sono stati specificati. */
--IF ele_variazioni IS NOT NULL AND ele_variazioni <> '' THEN
IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') OR
	 contaParVarPeg= 3 OR contaParVarBil = 3 OR p_code_sac_direz_peg <> '999' OR
     p_code_sac_direz_bil <> '999' THEN
	sql_query='
    insert into siac_rep_var_spese
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),
            tipo_elemento.elem_det_tipo_code,  ';
    sql_query=sql_query || ' '''||user_table||''' utente, '; 
    sql_query=sql_query || ' testata_variazione.ente_proprietario_id	,
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
            siac_t_periodo              anno_importo,
            siac_t_bil                  bilancio  ';
           
	if contaParVarPeg = 3 then 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto ,
            siac_d_atto_amm_tipo		tipo_atto,
			siac_r_atto_amm_stato 		r_atto_stato,
	        siac_d_atto_amm_stato 		stato_atto ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto2 ,
            siac_d_atto_amm_tipo		tipo_atto2,
			siac_r_atto_amm_stato 		r_atto_stato2,
	        siac_d_atto_amm_stato 		stato_atto2 ';
    end if;
    IF p_code_sac_direz_peg <> '999'  THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti'; 
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti2'; 
    END IF;          
       
    sql_query=sql_query||' where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
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
    
	if contaParVarPeg = 3 then 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id						=	atto.attoamm_id
    	and		atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
    	and 	atto.attoamm_id										= 	r_atto_stato.attoamm_id
    	and 	r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id_varbil				=	atto2.attoamm_id
    	and		atto2.attoamm_tipo_id								=	tipo_atto2.attoamm_tipo_id
    	and 	atto2.attoamm_id									= 	r_atto_stato2.attoamm_id
    	and 	r_atto_stato2.attoamm_stato_id						=	stato_atto2.attoamm_stato_id ';
    end if;
        
    IF p_code_sac_direz_peg <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id =ele_dir_sett_atti.attoamm_id ';
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id_varbil =ele_dir_sett_atti2.attoamm_id ';
    END IF;
  
    sql_query=sql_query || ' and testata_variazione.ente_proprietario_id	=  ' || p_ente_prop_id ||'     
    and		anno_eserc.anno			= 	'''||p_anno||'''
    and		tipologia_stato_var.variazione_stato_tipo_code in (''B'',''G'', ''C'', ''P'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCode|| '''    
    and		tipo_elemento.elem_det_tipo_code	in (''STA'',''SCA'',''STR'') ';
   
    IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
    	sql_query=sql_query || ' and testata_variazione.variazione_num in ('||p_ele_variazioni||') ';
    end if;
    if contaParVarPeg = 3 then 
    	sql_query=sql_query|| ' AND stato_atto.attoamm_stato_code <> ''ANNULLATO''  
        and 	atto.attoamm_numero ='||p_num_provv_var_peg||' 
    	and 	atto.attoamm_anno ='''||p_anno_provv_var_peg||'''
    	and		tipo_atto.attoamm_tipo_code='''||p_tipo_provv_var_peg||''' ';
    end if;
   
    if contaParVarBil = 3 then 
    	sql_query=sql_query||' AND stato_atto2.attoamm_stato_code <> ''ANNULLATO'' 
        and 	atto2.attoamm_numero ='||p_num_provv_var_bil||' 
    	and 	atto2.attoamm_anno ='''||p_anno_provv_var_bil||'''
    	and		tipo_atto2.attoamm_tipo_code='''||p_tipo_provv_var_bil||''' ';
    end if;
    
    IF p_code_sac_direz_peg <> '999' THEN
    	IF p_code_sac_sett_peg = 'T' THEN  -- qualunque settore.
    		sql_query=sql_query||'
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' ';
        ELSIF p_code_sac_sett_peg = '999' THEN -- settore non specificato, quindi atto legato solo ad una direzione.
        	sql_query=sql_query||'
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' 
        		and ele_dir_sett_atti.cod_sett ='''' ';
        ELSE sql_query=sql_query||'    -- = specificati un settore.
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' 
        		and ele_dir_sett_atti.cod_sett ='''||p_code_sac_sett_peg||'''';
        END IF;
    END IF;

    IF p_code_sac_direz_bil <> '999' THEN
    	IF p_code_sac_sett_bil = 'T' THEN  -- qualunque settore.
    		sql_query=sql_query||'
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' ';
        ELSIF p_code_sac_sett_bil = '999' THEN -- settore non specificato, quindi atto legato solo ad una direzione.
        	sql_query=sql_query||'
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' 
        		and ele_dir_sett_atti2.cod_sett ='''' ';
        ELSE sql_query=sql_query||'    -- = specificato un settore.
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' 
        		and ele_dir_sett_atti2.cod_sett ='''||p_code_sac_sett_bil||'''';
        END IF;
    END IF;
       
    sql_query=sql_query||'
    and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null ';
    if contaParVarPeg = 3 then 
    	sql_query=sql_query || ' and 	atto.data_cancellazione						is null
    	and 	tipo_atto.data_cancellazione				is null
    	and 	r_atto_stato.data_cancellazione				is null ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query || ' and 	atto2.data_cancellazione		is null
    	and 	tipo_atto2.data_cancellazione				is null
    	and 	r_atto_stato2.data_cancellazione			is null ';
    end if;
    sql_query=sql_query || ' group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                testata_variazione.ente_proprietario_id,
                anno_importo.anno';	     
         
raise notice 'Query: % ',  sql_query;      
EXECUTE sql_query;

RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  
raise notice '7.2: %', clock_timestamp()::varchar; 
   insert into siac_rep_var_spese_riga
select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        p_anno
from   
	siac_rep_cap_up tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=p_anno
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=p_anno
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=p_anno
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=p_anno
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=p_anno
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=p_anno
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  
   union
     select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
       annocapimp1
from   
	siac_rep_cap_up tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=annocapimp1
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=annocapimp1
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=annocapimp1
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=annocapimp1
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp1
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp1
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  
        union
     select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
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
	siac_rep_cap_up tb0 
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
        where  tb0.utente = user_table    ; 
end if;

-------------------------------------
 

       
-- PRIMA VERSIONE INIZIO      
----------------------------------------------------------------------------------------------------
--------  TABELLA TEMPORANEA PER ACQUISIRE L'IMPORTO DEL CUI GIA' IMPEGNATO 
--------  sostituisce momentaneamente le due query successive.
/*raise notice '9: %', clock_timestamp()::varchar;      
      RTN_MESSAGGIO:='insert tabella siac_rep_impegni_riga''.'; 
insert into  siac_rep_impegni_riga
select 	tb2.elem_id,
		tb2.dicuiimpegnato_anno1,
        tb2.dicuiimpegnato_anno2,
        tb2.dicuiimpegnato_anno3,
        p_ente_prop_id,
        user_table utente
from 	siac_t_dicuiimpegnato_bilprev 	tb2,
		siac_t_periodo 					anno_eserc,
    	siac_t_bil 						bilancio
where 	tb2.ente_proprietario_id = p_ente_prop_id				AND
		anno_eserc.anno= p_anno									and
        bilancio.periodo_id=anno_eserc.periodo_id				and
		tb2.bil_id = bilancio.bil_id;*/	
-- PRIMA VERSIONE FINE   
raise notice '8: %', clock_timestamp()::varchar; 

/* 13/05/2016: tolto il controllo sulla fase di bilancio 
select case when count(*) is null then 0 else 1 end into esiste_siac_t_dicuiimpegnato_bilprev 
from siac_t_dicuiimpegnato_bilprev where ente_proprietario_id=p_ente_prop_id limit 1;

if classifBilRec.fase_bilancio = 'P' and esiste_siac_t_dicuiimpegnato_bilprev<>1  then
  	for classifBilRec in */

-- NUOVA VERSIONE INIZIO
for ImpegniRec in
  select tb2.elem_id,
  tb.movgest_anno,
  p_ente_prop_id,
  user_table utente,
  tb.importo
  from (select    
  m.movgest_anno::VARCHAR, 
  e.elem_id,
  sum (tsd.movgest_ts_det_importo) importo
      from 
          siac_t_bil b, 
          siac_t_periodo p, 
          siac_t_bil_elem e,
          siac_d_bil_elem_tipo et,
          siac_r_movgest_bil_elem rm, 
          siac_t_movgest m,
          siac_d_movgest_tipo mt,
          siac_t_movgest_ts ts  ,
          siac_d_movgest_ts_tipo   tsti, 
          siac_r_movgest_ts_stato tsrs,
          siac_d_movgest_stato mst, 
          siac_t_movgest_ts_det   tsd ,
          siac_d_movgest_ts_det_tipo  tsdt
        where 
        b.periodo_id					=	p.periodo_id 
        and p.ente_proprietario_id   	= 	p_ente_prop_id
        and p.anno          			=   p_anno 
        and b.bil_id 					= 	e.bil_id
        and e.elem_tipo_id			=	et.elem_tipo_id
        and et.elem_tipo_code      	=  	elemTipoCode
        -------and et.elem_tipo_code      =  'CAP-UG'
        ----------and m.movgest_anno    <= annoCapImp_int
        and rm.elem_id      			= 	e.elem_id
        and rm.movgest_id      		=  	m.movgest_id 
        and now() between rm.validita_inizio and coalesce (rm.validita_fine, now())
        and m.movgest_anno::VARCHAR   			 in (annoCapImp, annoCapImp1, annoCapImp2)
        --and m.movgest_anno >= annobilint
        --------and m.bil_id     = b.bil_id --non serve
        and m.movgest_tipo_id			= 	mt.movgest_tipo_id 
        and mt.movgest_tipo_code		='I' 
        and m.movgest_id				=	ts.movgest_id
        and ts.movgest_ts_id			=	tsrs.movgest_ts_id 
        and tsrs.movgest_stato_id  	= 	mst.movgest_stato_id 
        and tsti.movgest_ts_tipo_code  = 'T' 
        and mst.movgest_stato_code   in ('D','N') ------ P,A,N 
        and now() between tsrs.validita_inizio and coalesce (tsrs.validita_fine, now())
        and ts.movgest_ts_tipo_id  	= 	tsti.movgest_ts_tipo_id 
        and ts.movgest_ts_id     		= 	tsd.movgest_ts_id 
        and tsd.movgest_ts_det_tipo_id  = tsdt.movgest_ts_det_tipo_id 
        and tsdt.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
        and now() between b.validita_inizio and coalesce (b.validita_fine, now())
        and now() between p.validita_inizio and coalesce (p.validita_fine, now())
        and now() between e.validita_inizio and coalesce (e.validita_fine, now())
        and now() between et.validita_inizio and coalesce (et.validita_fine, now())
        and now() between m.validita_inizio and coalesce (m.validita_fine, now())
        and now() between ts.validita_inizio and coalesce (ts.validita_fine, now())
        and now() between mt.validita_inizio and coalesce (ts.validita_fine, now())
        and now() between tsti.validita_inizio and coalesce (tsti.validita_fine, now())
        and now() between mst.validita_inizio and coalesce (mst.validita_fine, now())
        and now() between tsd.validita_inizio and coalesce (tsd.validita_fine, now())
        and now() between tsdt.validita_inizio and coalesce (tsdt.validita_fine, now())
        and p.data_cancellazione     	is null 
        and b.data_cancellazione      is null 
        and e.data_cancellazione      is null     
        and et.data_cancellazione     is null 
        and rm.data_cancellazione 	is null 
        and m.data_cancellazione      is null 
        and mt.data_cancellazione     is null 
        and ts.data_cancellazione   	is null 
        and tsti.data_cancellazione   is null 
        and tsrs.data_cancellazione   is null 
        and mst.data_cancellazione    is null 
        and tsd.data_cancellazione   	is null 
        and tsdt.data_cancellazione   is null      
  group by m.movgest_anno, e.elem_id )
  tb 
  ,
  (select * from  siac_t_bil_elem    			capitolo_ug,
                  siac_d_bil_elem_tipo    	t_capitolo_ug
        where capitolo_ug.elem_tipo_id		=	t_capitolo_ug.elem_tipo_id 
        and 	t_capitolo_ug.elem_tipo_code 	= 	elemTipoCode) tb2
  where
   tb2.elem_id	=	tb.elem_id
   
  LOOP
    
    v_importo_imp  :=0;
    v_importo_imp1 :=0;
    v_importo_imp2 :=0;
    
    IF ImpegniRec.movgest_anno = annoCapImp THEN
       v_importo_imp := ImpegniRec.importo;
    ELSIF ImpegniRec.movgest_anno = annoCapImp1 THEN
       v_importo_imp1 := ImpegniRec.importo;
    ELSIF ImpegniRec.movgest_anno = annoCapImp2 THEN  
       v_importo_imp2 := ImpegniRec.importo;
    END IF; 
        
    v_conta_rec := 0;
    SELECT count(elem_id)
    INTO   v_conta_rec
    FROM   SIAC_REP_IMPEGNI_RIGA
    WHERE  ente_proprietario = p_ente_prop_id
    AND    utente = ImpegniRec.utente
    AND    elem_id = ImpegniRec.elem_id;
    
    IF  v_conta_rec = 0 THEN
       
      INSERT INTO SIAC_REP_IMPEGNI_RIGA
          (elem_id,
           impegnato_anno,
           impegnato_anno1,
           impegnato_anno2,
           ente_proprietario,
           utente)
      VALUES
          (ImpegniRec.elem_id,
           v_importo_imp,
           v_importo_imp1,
           v_importo_imp2,
           p_ente_prop_id,
           ImpegniRec.utente
          );   
    ELSE
        IF ImpegniRec.movgest_anno = annoCapImp THEN
           UPDATE SIAC_REP_IMPEGNI_RIGA
           SET impegnato_anno = v_importo_imp
           WHERE  elem_id = ImpegniRec.elem_id
           AND    ente_proprietario = p_ente_prop_id
           AND    utente = ImpegniRec.utente;
        ELSIF  ImpegniRec.movgest_anno = annoCapImp1 THEN  
           UPDATE SIAC_REP_IMPEGNI_RIGA
           SET impegnato_anno1 = v_importo_imp1
           WHERE  elem_id = ImpegniRec.elem_id
           AND    ente_proprietario = p_ente_prop_id
           AND    utente = ImpegniRec.utente; 
        ELSIF ImpegniRec.movgest_anno = annoCapImp2 THEN                   
           UPDATE SIAC_REP_IMPEGNI_RIGA
           SET impegnato_anno2 = v_importo_imp2
           WHERE  elem_id = ImpegniRec.elem_id
           AND    ente_proprietario = p_ente_prop_id
           AND    utente = ImpegniRec.utente;   
        END IF;             
    END IF;
        
  END LOOP; 
   
-- NUOVA VERSIONE FINE  

 RTN_MESSAGGIO:='preparazione file output''.'; 
 
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
            --------t1.elem_id_old		elem_id_old,
            COALESCE(t2.impegnato_anno,0) impegnato_anno,
            COALESCE(t2.impegnato_anno1,0) impegnato_anno1,
            COALESCE(t2.impegnato_anno2,0) impegnato_anno2,
            COALESCE (var_anno.variazione_aumento_cassa, 0)		variazione_aumento_cassa,
            COALESCE (var_anno.variazione_aumento_residuo, 0)	variazione_aumento_residuo,
            COALESCE (var_anno.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato,
            COALESCE (var_anno.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa,
            COALESCE (var_anno.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo,
            COALESCE (var_anno.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato,
            COALESCE (var_anno1.variazione_aumento_cassa, 0)		variazione_aumento_cassa1,
            COALESCE (var_anno1.variazione_aumento_residuo, 0)	variazione_aumento_residuo1,
            COALESCE (var_anno1.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato1,
            COALESCE (var_anno1.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa1,
            COALESCE (var_anno1.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo1,
            COALESCE (var_anno1.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato1,
            COALESCE (var_anno2.variazione_aumento_cassa, 0)		variazione_aumento_cassa2,
            COALESCE (var_anno2.variazione_aumento_residuo, 0)	variazione_aumento_residuo2,
            COALESCE (var_anno2.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato2,
            COALESCE (var_anno2.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa2,
            COALESCE (var_anno2.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo2,
            COALESCE (var_anno2.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato2
                      
    from siac_rep_mptm_up_cap_importi t1
            ----full join siac_rep_impegni_riga  t2
            left join siac_rep_impegni_riga  t2
            on (t1.elem_id	=	t2.elem_id)  ---------da sostituire con   --------t1.elem_id_old	=	t2.elem_id
                --and	t1.ente_proprietario_id	=	t2.ente_proprietario
                ----and	t1.utente	=	t2.utente
                ----and	t1.utente	=	user_table)
		left	join  siac_rep_var_spese_riga var_anno 
           			on (var_anno.elem_id	=	t1.elem_id
                    	and var_anno.periodo_anno= annoCapImp
                    	and	t1.utente=user_table
                        and var_anno.utente	=	t1.utente)         
			left	join  siac_rep_var_spese_riga var_anno1
           			on (var_anno1.elem_id	=	t1.elem_id
                    	and var_anno1.periodo_anno= annoCapImp1
                    	and	t1.utente=user_table
                        and var_anno1.utente	=	t1.utente)  
			left	join  siac_rep_var_spese_riga var_anno2
           			on (var_anno2.elem_id	=	t1.elem_id
                    	and var_anno2.periodo_anno= annoCapImp2
                    	and	t1.utente=user_table
                        and var_anno2.utente	=	t1.utente)                    
            where t1.utente = user_table
         /*  06/09/2016: eliminate queste condizioni perche' il filtro
         		e' nella query di caricamento struttura
         	 and	(
        		(t1.missione_code < '20' and t1.titusc_code in ('1','2','3'))
        		or (t1.missione_code = '20' and t1.programma_code='2001' and t1.titusc_code = '1')
                or (t1.missione_code = '20' and t1.programma_code in ('2002','2003') and t1.titusc_code in ('1','2'))
                or (t1.missione_code = '50' and t1.programma_code='5001' and t1.titusc_code = '1')
                or (t1.missione_code = '50' and t1.programma_code='5002' and t1.titusc_code = '4')
                or (t1.missione_code = '60' and t1.programma_code = '6001' and t1.titusc_code in ('1','5'))
                or (t1.missione_code = '99' and t1.programma_code in ('9901','9902') and t1.titusc_code = '7')
                )*/
            order by missione_code,programma_code,titusc_code,macroag_code   	
loop
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
      bil_ele_desc2:=classifBilRec.bil_ele_desc2;
      bil_ele_id:=classifBilRec.bil_ele_id;
      bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
      bil_anno:=p_anno;
      stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
      stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
      stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;
      stanziamento_prev_res_anno:=classifBilRec.stanziamento_prev_res_anno;
      stanziamento_anno_prec:=classifBilRec.stanziamento_anno_prec;
      stanziamento_prev_cassa_anno:=classifBilRec.stanziamento_prev_cassa_anno;
      --stanziamento_fpv_anno_prec:=classifBilRec.stanziamento_fpv_anno_prec;
      stanziamento_fpv_anno_prec_app:=classifBilRec.stanziamento_fpv_anno_prec;
      stanziamento_fpv_anno:=classifBilRec.stanziamento_fpv_anno; 
      stanziamento_fpv_anno1:=classifBilRec.stanziamento_fpv_anno1; 
      stanziamento_fpv_anno2:=classifBilRec.stanziamento_fpv_anno2;
      impegnato_anno:=classifBilRec.impegnato_anno;
      impegnato_anno1:=classifBilRec.impegnato_anno1;
      impegnato_anno2=classifBilRec.impegnato_anno2;
      
      --stanziamento_fpv_anno_prec

--25/07/2016: sommo gli eventuali valori delle variazioni

--stanziamento_prev_anno=stanziamento_prev_anno+classifBilRec.variazione_aumento_stanziato+
--            					    classifBilRec.variazione_diminuzione_stanziato;
                                    
stanziamento_prev_cassa_anno=stanziamento_prev_cassa_anno+classifBilRec.variazione_aumento_cassa+
            					    classifBilRec.variazione_diminuzione_cassa;                                    
--stanziamento_prev_anno1=stanziamento_prev_anno1+classifBilRec.variazione_aumento_stanziato1+
--            					    classifBilRec.variazione_diminuzione_stanziato1;
                                    
--stanziamento_prev_anno2=stanziamento_prev_anno2+classifBilRec.variazione_aumento_stanziato2+
--            					    classifBilRec.variazione_diminuzione_stanziato2;

stanziamento_prev_res_anno=stanziamento_prev_res_anno+classifBilRec.variazione_aumento_residuo+
            					    classifBilRec.variazione_diminuzione_residuo;

select b.elem_cat_code into cat_capitolo from siac_r_bil_elem_categoria a, siac_d_bil_elem_categoria b
where a.elem_id=classifBilRec.bil_ele_id 
and a.data_cancellazione is null
and a.validita_fine is null
and a.elem_cat_id=b.elem_cat_id;

--raise notice 'XXXX tipo_categ_capitolo = %', cat_capitolo;
--raise notice 'XXXX elem id = %', classifBilRec.bil_ele_id ;


if cat_capitolo = 'FPV' or cat_capitolo = 'FPVC' then 
stanziamento_fpv_anno=stanziamento_fpv_anno+classifBilRec.variazione_aumento_stanziato+
            					    classifBilRec.variazione_diminuzione_stanziato;

stanziamento_fpv_anno1=stanziamento_fpv_anno1+classifBilRec.variazione_aumento_stanziato1+
            					    classifBilRec.variazione_diminuzione_stanziato1;
stanziamento_fpv_anno2=stanziamento_fpv_anno2+classifBilRec.variazione_aumento_stanziato2+
            					    classifBilRec.variazione_diminuzione_stanziato2;
else

stanziamento_prev_anno=stanziamento_prev_anno+classifBilRec.variazione_aumento_stanziato+
            					    classifBilRec.variazione_diminuzione_stanziato;
	
stanziamento_prev_anno1=stanziamento_prev_anno1+classifBilRec.variazione_aumento_stanziato1+
            					    classifBilRec.variazione_diminuzione_stanziato1;
                                    
stanziamento_prev_anno2=stanziamento_prev_anno2+classifBilRec.variazione_aumento_stanziato2+
            					    classifBilRec.variazione_diminuzione_stanziato2;

end if;

/* if classifBilRec.variazione_aumento_stanziato <> 0 OR
	classifBilRec.variazione_diminuzione_stanziato <> 0 OR
    classifBilRec.variazione_aumento_cassa <> 0 OR
    classifBilRec.variazione_diminuzione_cassa <> 0 OR    
    classifBilRec.variazione_aumento_stanziato1 <> 0 OR
    classifBilRec.variazione_diminuzione_stanziato1 <> 0 OR
    classifBilRec.variazione_aumento_stanziato2 <> 0 OR
    classifBilRec.variazione_diminuzione_stanziato2 <> 0 OR  
    classifBilRec.variazione_aumento_residuo <> 0 OR
    classifBilRec.variazione_diminuzione_residuo <> 0 THEN
raise notice 'Cap %, ID = %, Missione = %, Programma = %, Titolo %', bil_ele_code, bil_ele_id, missione_code, programma_code, titusc_code;
raise notice '  variazione_aumento_stanziato = %',classifBilRec.variazione_aumento_stanziato;
raise notice '  variazione_diminuzione_stanziato = %',classifBilRec.variazione_diminuzione_stanziato;
raise notice '  variazione_aumento_cassa = %',classifBilRec.variazione_aumento_cassa;
raise notice '  variazione_diminuzione_cassa = %',classifBilRec.variazione_diminuzione_cassa;
raise notice '  variazione_aumento_stanziato1 = %',classifBilRec.variazione_aumento_stanziato1;
raise notice '  variazione_diminuzione_stanziato1 = %',classifBilRec.variazione_diminuzione_stanziato1;
raise notice '  variazione_aumento_stanziato2 = %',classifBilRec.variazione_aumento_stanziato2;
raise notice '  variazione_diminuzione_stanziato2 = %',classifBilRec.variazione_diminuzione_stanziato2;
raise notice '  variazione_aumento_residuo = %',classifBilRec.variazione_aumento_residuo;
raise notice '  variazione_diminuzione_residuo = %',classifBilRec.variazione_diminuzione_residuo;

end if;  */

--06/05/2016: cerco i dati relativi alle previsioni anno precedente.
IF bil_ele_code IS NOT NULL THEN
--raise notice 'Cerco: missione_code=%, programma_code=%, titolo_code=%, macroagg_code=%,  bil_ele_code=%, bil_ele_code2=%, bil_ele_code3= %, anno=%', missione_code, classifBilRec.programma_code, classifBilRec.titusc_code,classifBilRec.macroag_code,bil_ele_code,bil_ele_code2, classifBilRec.BIL_ELE_CODE3, annoPrec;

  SELECT COALESCE(imp_prev_anno_prec.importo_cassa,0) importo_cassa,
          COALESCE(imp_prev_anno_prec.importo_competenza, 0) importo_competenza,
          elem_cat_code
  INTO previsioni_anno_prec_cassa_app, previsioni_anno_prec_comp_app, tipo_categ_capitolo
  FROM siac_t_cap_u_importi_anno_prec  imp_prev_anno_prec 
  WHERE  --imp_prev_anno_prec.missione_code= classifBilRec.missione_code
       imp_prev_anno_prec.programma_code=classifBilRec.programma_code
      --AND imp_prev_anno_prec.titolo_code=classifBilRec.titusc_code      
      AND imp_prev_anno_prec.macroagg_code=classifBilRec.macroag_code
      AND imp_prev_anno_prec.elem_code=bil_ele_code
      AND imp_prev_anno_prec.elem_code2=bil_ele_code2
      AND imp_prev_anno_prec.elem_code3=classifBilRec.BIL_ELE_CODE3
      AND imp_prev_anno_prec.anno= annoPrec
      AND imp_prev_anno_prec.ente_proprietario_id=p_ente_prop_id
      AND imp_prev_anno_prec.data_cancellazione IS NULL;
  IF NOT FOUND THEN 
      previsioni_anno_prec_comp=0;
      previsioni_anno_prec_cassa=0;
      stanziamento_fpv_anno_prec=0;
  ELSE
 -- raise notice 'XXXX tipo_categ_capitolo = %', tipo_categ_capitolo;
      previsioni_anno_prec_comp=previsioni_anno_prec_comp_app;
      previsioni_anno_prec_cassa=previsioni_anno_prec_cassa_app;
      	-- se il capitolo e' di tipo FPV carico anche il campo stanziamento_fpv_anno_prec
     -- 06/09/2016: aggiunto FPVC
 	 IF tipo_categ_capitolo = 'FPV' OR tipo_categ_capitolo = 'FPVC' THEN
      	previsioni_anno_prec_comp=0;
      	stanziamento_fpv_anno_prec=previsioni_anno_prec_comp_app;  
      END IF;
  END IF;
ELSE
      previsioni_anno_prec_comp=0;
      previsioni_anno_prec_cassa=0;
      stanziamento_fpv_anno_prec=0;
END IF;
--06/05/2016: in prima battuta la tabella siac_t_cap_e_importi_anno_prec NON
-- conterra' i dati della competenza ma solo quelli della cassa, pertanto
-- il dato della competenza letto dalla tabella e' sostituito da quello che
-- era contenuto nel campo previsioni_anno_prec.
-- Quando sara' valorizzato le seguenti righe dovranno ESSERE ELIMINATE!!!
--previsioni_anno_prec_comp=stanziamento_anno_prec;
--stanziamento_fpv_anno_prec=stanziamento_fpv_anno_prec_app;

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
    bil_ele_desc2='';
    bil_ele_id=0;
    bil_ele_id_padre=0;
    stanziamento_prev_res_anno=0;
    stanziamento_anno_prec=0;
    stanziamento_prev_cassa_anno=0;
    stanziamento_prev_anno=0;
    stanziamento_prev_anno1=0;
    stanziamento_prev_anno2=0;
    impegnato_anno=0;
    impegnato_anno1=0;
    impegnato_anno2=0;
    stanziamento_fpv_anno_prec=0;
    stanziamento_fpv_anno=0;
    stanziamento_fpv_anno1=0;
    stanziamento_fpv_anno2=0;
    previsioni_anno_prec_comp=0;
	previsioni_anno_prec_cassa=0;
	stanziamento_fpv_anno_prec=0;

end loop;


delete from siac_rep_mis_pro_tit_mac_riga_anni 		where utente=user_table;
delete from siac_rep_cap_up 						where utente=user_table;
delete from siac_rep_cap_up_imp 					where utente=user_table;
delete from siac_rep_cap_up_imp_riga				where utente=user_table;
delete from siac_rep_mptm_up_cap_importi 			where utente=user_table;
delete from siac_rep_impegni 						where utente=user_table;
delete from siac_rep_impegni_riga  					where utente=user_table;
delete from siac_rep_var_spese  					where utente=user_table;
delete from siac_rep_var_spese_riga  				where utente=user_table;

raise notice 'fine OK';
    exception
    when no_data_found THEN
      raise notice 'nessun dato trovato per struttura bilancio';
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

CREATE OR REPLACE FUNCTION siac."BILR112_Allegato_9_bill_gest_quadr_riass_gen_entrate" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_altri_imp boolean,
  p_ele_variazioni varchar,
  p_num_provv_var_peg integer,
  p_anno_provv_var_peg varchar,
  p_tipo_provv_var_peg varchar,
  p_num_provv_var_bil integer,
  p_anno_provv_var_bil varchar,
  p_tipo_provv_var_bil varchar,
  p_code_sac_direz_peg varchar,
  p_code_sac_sett_peg varchar,
  p_code_sac_direz_bil varchar,
  p_code_sac_sett_bil varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titent_tipo_code varchar,
  titent_tipo_desc varchar,
  titent_code varchar,
  titent_desc varchar,
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
  display_error varchar
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
titoloe_tipo_code varchar;
titoloe_TIPO_DESC varchar;
titoloe_CODE varchar;
titoloe_DESC varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
strApp VARCHAR;
intApp INTEGER;
-- DAVIDE - SIAC-5202 - oltre 4 variazioni, il codice si sfonda
x_array VARCHAR [];
-- DAVIDE - SIAC-5202 - FINE
sql_query VARCHAR;
v_fam_titolotipologiacategoria varchar:='00003';

contaParVarPeg integer;
contaParVarBil integer;

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpresidui='STR'; -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
TipoImpCassa ='SCA'; ----- previsioni di cassa
elemTipoCode:='CAP-EG'; -- tipo capitolo previsione
contaParVarPeg:=0;
contaParVarBil:=0;

bil_anno='';
titent_tipo_code='';
titent_tipo_desc='';
titent_code='';
titent_desc='';
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
stanziamento_prev_cassa_anno:=0;

-- lettura della struttura di bilancio
-- impostazione dell'ente proprietario sulle classificazioni

display_error='';

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  -- DAVIDE - SIAC-5202 - oltre 4 variazioni, il codice si sfonda
  x_array = string_to_array(p_ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    --strApp=REPLACE(p_ele_variazioni,',','');
    --raise notice 'VAR: %', strApp;
    intApp = strApp::INTEGER;
  END LOOP;
  -- DAVIDE - SIAC-5202 - FINE
END IF;

/* 25/09/2017: parametri nuovi, controllo che se e' passato uno tra numero/anno/tipo
    	provvedimento di variazione di PEG o di BILANCIO, siano passati anche
        gli altri 2. */
if p_num_provv_var_peg IS NOT  NULL THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if p_anno_provv_var_peg IS NOT  NULL AND p_anno_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if p_tipo_provv_var_peg IS NOT  NULL AND p_tipo_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if contaParVarPeg not in (0,3) then
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di PEG''';
    return next;
    return;        
end if;

if p_num_provv_var_bil IS NOT  NULL THEN
	contaParVarBil=contaParVarBil+1;
end if;
if p_anno_provv_var_bil IS NOT  NULL AND p_anno_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
end if;
if p_tipo_provv_var_bil IS NOT  NULL AND p_tipo_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
end if;
if contaParVarBil not in (0,3) then
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di Bilancio''';
    return next;
    return;        
end if;

/*display_error :='p_num_provv_var_bil = '||p_num_provv_var_bil|| ', p_anno_provv_var_bil= '||p_anno_provv_var_bil ||' ,p_tipo_provv_var_bil='||p_tipo_provv_var_bil; 

    return next;
    return; */
    
select fnc_siac_random_user()
into	user_table;
 	
/*
insert into  siac_rep_tit_tip_cat_riga_anni
select v.*,user_table from
(SELECT v3.classif_tipo_desc AS classif_tipo_desc1, v3.classif_id AS titolo_id,
    v3.classif_code AS titolo_code, v3.classif_desc AS titolo_desc,
    v3.validita_inizio AS titolo_validita_inizio,
    v3.validita_fine AS titolo_validita_fine,
    v2.classif_tipo_desc AS classif_tipo_desc2, v2.classif_id AS tipologia_id,
    v2.classif_code AS tipologia_code, v2.classif_desc AS tipologia_desc,
    v2.validita_inizio AS tipologia_validita_inizio,
    v2.validita_fine AS tipologia_validita_fine,
    v1.classif_tipo_desc AS classif_tipo_desc3, v1.classif_id AS categoria_id,
    v1.classif_code AS categoria_code, v1.classif_desc AS categoria_desc,
    v1.validita_inizio AS categoria_validita_inizio,
    v1.validita_fine AS categoria_validita_fine, v1.ente_proprietario_id
FROM (SELECT tb.classif_classif_fam_tree_id, tb.classif_fam_tree_id, t1.classif_code,
    t1.classif_desc, ti1.classif_tipo_desc, tb.classif_id, tb.classif_id_padre,
    tb.ente_proprietario_id, tb.ordine, tb.level, tb.validita_inizio,
    tb.validita_fine
FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
    classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, validita_inizio, validita_fine, level, arrhierarchy) AS (
    SELECT rt1.classif_classif_fam_tree_id,
                            rt1.classif_fam_tree_id, rt1.classif_id,
                            rt1.classif_id_padre, rt1.ente_proprietario_id,
                            rt1.ordine, rt1.livello, tt1.validita_inizio,
                            tt1.validita_fine, 1,
                            ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
    FROM siac_r_class_fam_tree rt1,
                            siac_t_class_fam_tree tt1, siac_d_class_fam cf
    WHERE cf.classif_fam_id = tt1.classif_fam_id AND tt1.classif_fam_tree_id =
        rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_desc::text = 'Entrata - TitoliTipologieCategorie'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id
    UNION ALL
    SELECT tn.classif_classif_fam_tree_id,
                            tn.classif_fam_tree_id, tn.classif_id,
                            tn.classif_id_padre, tn.ente_proprietario_id,
                            tn.ordine, tn.livello, tn.validita_inizio,
                            tn.validita_fine, tp.level + 1,
                            tp.arrhierarchy || tn.classif_id
    FROM rqname tp, siac_r_class_fam_tree tn
    WHERE tp.classif_id = tn.classif_id_padre AND tn.ente_proprietario_id =
        tp.ente_proprietario_id
    )
    SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
            rqname.classif_id, rqname.classif_id_padre,
            rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
            rqname.validita_inizio, rqname.validita_fine, rqname.level
    FROM rqname
    ORDER BY rqname.arrhierarchy
    ) tb, siac_t_class t1,
    siac_d_class_tipo ti1
WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id =
    t1.classif_tipo_id AND t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND ti1.ente_proprietario_id = t1.ente_proprietario_id) v1,
-------------siac_v_tit_tip_cat_anni v1,
(SELECT tb.classif_classif_fam_tree_id, tb.classif_fam_tree_id, t1.classif_code,
    t1.classif_desc, ti1.classif_tipo_desc, tb.classif_id, tb.classif_id_padre,
    tb.ente_proprietario_id, tb.ordine, tb.level, tb.validita_inizio,
    tb.validita_fine
FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
    classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, validita_inizio, validita_fine, level, arrhierarchy) AS (
    SELECT rt1.classif_classif_fam_tree_id,
                            rt1.classif_fam_tree_id, rt1.classif_id,
                            rt1.classif_id_padre, rt1.ente_proprietario_id,
                            rt1.ordine, rt1.livello, tt1.validita_inizio,
                            tt1.validita_fine, 1,
                            ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
    FROM siac_r_class_fam_tree rt1,
                            siac_t_class_fam_tree tt1, siac_d_class_fam cf
    WHERE cf.classif_fam_id = tt1.classif_fam_id AND tt1.classif_fam_tree_id =
        rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_desc::text = 'Entrata - TitoliTipologieCategorie'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id
    UNION ALL
    SELECT tn.classif_classif_fam_tree_id,
                            tn.classif_fam_tree_id, tn.classif_id,
                            tn.classif_id_padre, tn.ente_proprietario_id,
                            tn.ordine, tn.livello, tn.validita_inizio,
                            tn.validita_fine, tp.level + 1,
                            tp.arrhierarchy || tn.classif_id
    FROM rqname tp, siac_r_class_fam_tree tn
    WHERE tp.classif_id = tn.classif_id_padre AND tn.ente_proprietario_id =
        tp.ente_proprietario_id
    )
    SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
            rqname.classif_id, rqname.classif_id_padre,
            rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
            rqname.validita_inizio, rqname.validita_fine, rqname.level
    FROM rqname
    ORDER BY rqname.arrhierarchy
    ) tb, siac_t_class t1,
    siac_d_class_tipo ti1
WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id =
    t1.classif_tipo_id AND t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND ti1.ente_proprietario_id = t1.ente_proprietario_id) v2, 
----------siac_v_tit_tip_cat_anni v2,
(SELECT tb.classif_classif_fam_tree_id, tb.classif_fam_tree_id, t1.classif_code,
    t1.classif_desc, ti1.classif_tipo_desc, tb.classif_id, tb.classif_id_padre,
    tb.ente_proprietario_id, tb.ordine, tb.level, tb.validita_inizio,
    tb.validita_fine
FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
    classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, validita_inizio, validita_fine, level, arrhierarchy) AS (
    SELECT rt1.classif_classif_fam_tree_id,
                            rt1.classif_fam_tree_id, rt1.classif_id,
                            rt1.classif_id_padre, rt1.ente_proprietario_id,
                            rt1.ordine, rt1.livello, tt1.validita_inizio,
                            tt1.validita_fine, 1,
                            ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
    FROM siac_r_class_fam_tree rt1,
                            siac_t_class_fam_tree tt1, siac_d_class_fam cf
    WHERE cf.classif_fam_id = tt1.classif_fam_id AND tt1.classif_fam_tree_id =
        rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_desc::text = 'Entrata - TitoliTipologieCategorie'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id
    UNION ALL
    SELECT tn.classif_classif_fam_tree_id,
                            tn.classif_fam_tree_id, tn.classif_id,
                            tn.classif_id_padre, tn.ente_proprietario_id,
                            tn.ordine, tn.livello, tn.validita_inizio,
                            tn.validita_fine, tp.level + 1,
                            tp.arrhierarchy || tn.classif_id
    FROM rqname tp, siac_r_class_fam_tree tn
    WHERE tp.classif_id = tn.classif_id_padre AND tn.ente_proprietario_id =
        tp.ente_proprietario_id
    )
    SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
            rqname.classif_id, rqname.classif_id_padre,
            rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
            rqname.validita_inizio, rqname.validita_fine, rqname.level
    FROM rqname
    ORDER BY rqname.arrhierarchy
    ) tb, siac_t_class t1,
    siac_d_class_tipo ti1
WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id =
    t1.classif_tipo_id AND t1.ente_proprietario_id = tb.ente_proprietario_id
     AND ti1.ente_proprietario_id = t1.ente_proprietario_id) v3
---------------    siac_v_tit_tip_cat_anni v3
WHERE v1.classif_id_padre = v2.classif_id AND v1.classif_tipo_desc::text =
    'Categoria'::text AND v2.classif_tipo_desc::text = 'Tipologia'::text 
    AND v2.classif_id_padre = v3.classif_id AND v3.classif_tipo_desc::text = 'Titolo Entrata'::text 
    AND v1.ente_proprietario_id = v2.ente_proprietario_id AND v2.ente_proprietario_id = v3.ente_proprietario_id) v
---------siac_v_tit_tip_cat_riga_anni v 
where v.ente_proprietario_id=p_ente_prop_id 
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between v.categoria_validita_inizio and
COALESCE(v.categoria_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between v.tipologia_validita_inizio and
COALESCE(v.tipologia_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between v.titolo_validita_inizio and
COALESCE(v.titolo_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
order by titolo_code, tipologia_code,categoria_code;
*/


--06/09/2016: cambiata la query che carica la struttura di bilancio
--  per motivi prestazionali
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
and anno_eserc.anno				= p_anno
and bilancio.periodo_id			=anno_eserc.periodo_id 
and e.bil_id					=bilancio.bil_id 
and e.elem_tipo_id				=tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code = elemTipoCode
and e.elem_id					=rc.elem_id 
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	stato_capitolo.elem_stato_code	=	'VA'
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and	cat_del_capitolo.elem_cat_code	=	'STD'
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


insert into siac_rep_cap_ep_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo)       
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
        and	anno_eserc.anno						= p_anno 												
    	and	bilancio.periodo_id					=anno_eserc.periodo_id 								
        and	capitolo.bil_id						=bilancio.bil_id 			 
        and	capitolo.elem_id					=capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		=elemTipoCode
        and	capitolo_importi.elem_det_tipo_id	=capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)
       and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code		=	'STD'
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
    group by   capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;


insert into siac_rep_cap_ep_imp_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		stanziamento_prev_anno,
    	tb2.importo 	as		stanziamento_prev_anno1,
    	tb3.importo		as		stanziamento_prev_anno2,
   	 	tb4.importo		as		residui_presunti,
    	tb5.importo		as		previsioni_anno_prec,
    	tb6.importo		as		stanziamento_prev_cassa_anno,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_ep_imp tb1, siac_rep_cap_ep_imp tb2, siac_rep_cap_ep_imp tb3,
	siac_rep_cap_ep_imp tb4, siac_rep_cap_ep_imp tb5, siac_rep_cap_ep_imp tb6
	where			
    	tb1.elem_id	=	tb2.elem_id
        and 
        tb2.elem_id	=	tb3.elem_id
        and 
        tb3.elem_id	=	tb4.elem_id
        and 
        tb4.elem_id	=	tb5.elem_id
        and 
        tb5.elem_id	=	tb6.elem_id
        and
    	tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp	
        AND
        tb2.periodo_anno = annoCapImp1	AND	tb1.tipo_imp =	tb2.tipo_imp 
        and
        tb3.periodo_anno = annoCapImp2	AND	tb2.tipo_imp =	tb3.tipo_imp 
        and 
    	tb4.periodo_anno = tb1.periodo_anno AND	tb4.tipo_imp = 	TipoImpresidui
        and 
    	tb5.periodo_anno = tb1.periodo_anno AND	tb5.tipo_imp = 	TipoImpstanzresidui
        and 
    	tb6.periodo_anno = tb1.periodo_anno AND	tb6.tipo_imp = 	TipoImpCassa
        and tb1.utente 	= 	tb2.utente	
        and	tb2.utente	=	tb3.utente
        and	tb3.utente	=	tb4.utente
        and	tb4.utente	=	tb5.utente
        and tb5.utente	=	tb6.utente
        and	tb6.utente	=	user_table;
                
-------------------------------------
--26/07/2016:
--se sono state specificate delle variazioni cerco i relativi valori
/* 26/09/2017: aggiunto anche il controllo relativo ai parametri degli atti.
	Nelle variabili contaParVarPeg e contaParVarBil sono contenuti il numero di parametri 
	riguardanti le delibere PEG e Bilancio; se sono 3 (numero, anno e tipo) significa
    che quel parametro e' stato passato e quindi devo aggiungere il filtro. 
    Aggiunto anche il controllo relativo alle direzione e settori.
    Se p_code_sac_direz_peg e p_code_sac_direz_bil sono uguali a 999 significa che NON
    sono stati specificati. */
--IF ele_variazioni IS NOT NULL AND ele_variazioni <> '' THEN    
IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') OR
	 contaParVarPeg= 3 OR contaParVarBil = 3 OR p_code_sac_direz_peg <> '999' OR
     p_code_sac_direz_bil <> '999' THEN
	sql_query='
    insert into siac_rep_var_entrate
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),
            tipo_elemento.elem_det_tipo_code,  ';
    sql_query=sql_query || ' '''||user_table||''' utente, '; 
    sql_query=sql_query || ' testata_variazione.ente_proprietario_id	,
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
            siac_t_periodo              anno_importo,
            siac_t_bil                  bilancio ';
 if contaParVarPeg = 3 then 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto ,
            siac_d_atto_amm_tipo		tipo_atto,
			siac_r_atto_amm_stato 		r_atto_stato,
	        siac_d_atto_amm_stato 		stato_atto ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto2 ,
            siac_d_atto_amm_tipo		tipo_atto2,
			siac_r_atto_amm_stato 		r_atto_stato2,
	        siac_d_atto_amm_stato 		stato_atto2 ';
    end if;
    IF p_code_sac_direz_peg <> '999'  THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti'; 
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti2'; 
    END IF;            
    sql_query=sql_query||' where r_variazione_stato.variazione_id	=	testata_variazione.variazione_id
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
	if contaParVarPeg = 3 then 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id						=	atto.attoamm_id
    	and		atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
    	and 	atto.attoamm_id										= 	r_atto_stato.attoamm_id
    	and 	r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id_varbil				=	atto2.attoamm_id
    	and		atto2.attoamm_tipo_id								=	tipo_atto2.attoamm_tipo_id
    	and 	atto2.attoamm_id									= 	r_atto_stato2.attoamm_id
    	and 	r_atto_stato2.attoamm_stato_id						=	stato_atto2.attoamm_stato_id ';
    end if;
        
    IF p_code_sac_direz_peg <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id =ele_dir_sett_atti.attoamm_id ';
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id_varbil =ele_dir_sett_atti2.attoamm_id ';
    END IF;    
    sql_query=sql_query||' and	testata_variazione.ente_proprietario_id	= ' || p_ente_prop_id;
    sql_query=sql_query || ' and		anno_eserc.anno			= 	'''||p_anno||'''
    and		tipologia_stato_var.variazione_stato_tipo_code in (''B'',''G'', ''C'', ''P'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCode|| '''    
    and		tipo_elemento.elem_det_tipo_code	in (''STA'',''SCA'',''STR'') ';
    IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
    	sql_query=sql_query || ' and testata_variazione.variazione_num in ('||p_ele_variazioni||') ';
    end if;
    if contaParVarPeg = 3 then 
    	sql_query=sql_query||' AND stato_atto.attoamm_stato_code <> ''ANNULLATO'' 
        and 	atto.attoamm_numero ='||p_num_provv_var_peg||' 
    	and 	atto.attoamm_anno ='''||p_anno_provv_var_peg||'''
    	and		tipo_atto.attoamm_tipo_code='''||p_tipo_provv_var_peg||''' ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||' AND stato_atto2.attoamm_stato_code <> ''ANNULLATO'' 
        and 	atto2.attoamm_numero ='||p_num_provv_var_bil||' 
    	and 	atto2.attoamm_anno ='''||p_anno_provv_var_bil||'''
    	and		tipo_atto2.attoamm_tipo_code='''||p_tipo_provv_var_bil||''' ';
    end if;
    IF p_code_sac_direz_peg <> '999' THEN
    	IF p_code_sac_sett_peg = 'T' THEN  -- qualunque settore.
    		sql_query=sql_query||'
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' ';
        ELSIF p_code_sac_sett_peg = '999' THEN -- settore non specificato, quindi atto legato solo ad una direzione.
        	sql_query=sql_query||'
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' 
        		and ele_dir_sett_atti.cod_sett ='''' ';
        ELSE sql_query=sql_query||'    -- = specificati un settore.
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' 
        		and ele_dir_sett_atti.cod_sett ='''||p_code_sac_sett_peg||'''';
        END IF;
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	IF p_code_sac_sett_bil = 'T' THEN  -- qualunque settore.
    		sql_query=sql_query||'
        		and ele_dir_sett_atti2.cod_direz = '''||code_sac_direz_bil||''' ';
        ELSIF p_code_sac_sett_bil = '999' THEN -- settore non specificato, quindi atto legato solo ad una direzione.
        	sql_query=sql_query||'
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' 
        		and ele_dir_sett_atti2.cod_sett ='''' ';
        ELSE sql_query=sql_query||'    -- = specificato un settore.
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' 
        		and ele_dir_sett_atti2.cod_sett ='''||p_code_sac_sett_bil||'''';
        END IF;
    END IF; 
    sql_query=sql_query||' and	r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null ';
    if contaParVarPeg = 3 then 
    	sql_query=sql_query || ' and 	atto.data_cancellazione						is null
    	and 	tipo_atto.data_cancellazione				is null
    	and 	r_atto_stato.data_cancellazione				is null ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query || ' and 	atto2.data_cancellazione		is null
    	and 	tipo_atto2.data_cancellazione				is null
    	and 	r_atto_stato2.data_cancellazione			is null ';
    end if;
    sql_query=sql_query || ' group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                testata_variazione.ente_proprietario_id,
                anno_importo.anno';	     
         
raise notice 'Query: % ',  sql_query;      
EXECUTE sql_query;

RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  

    insert into siac_rep_var_entrate_riga
    select  tb0.elem_id,     
            tb1.importo   as 		variazione_aumento_stanziato,
            tb2.importo   as 		variazione_diminuzione_stanziato,
            tb3.importo   as 		variazione_aumento_cassa,
            tb4.importo   as 		variazione_diminuzione_cassa,
            tb5.importo   as 		variazione_aumento_residuo,
            tb6.importo   as 		variazione_diminuzione_residuo,
            user_table utente,
            p_ente_prop_id,
            p_anno
    from   
        siac_rep_cap_ep tb0 
        left join siac_rep_var_entrate tb1
         on (tb1.elem_id		=	tb0.elem_id	
            and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
            and tb1.periodo_anno=p_anno
            and tb1.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb2
        on (tb2.elem_id		=	tb0.elem_id
            and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
            and tb2.periodo_anno=p_anno
            and tb2.utente = tb0.utente )
        left join siac_rep_var_entrate tb3
         on (tb3.elem_id		=	tb0.elem_id	
            and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
            and tb3.periodo_anno=p_anno
            and tb3.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb4
        on (tb4.elem_id		=	tb0.elem_id
            and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
            and tb4.periodo_anno=p_anno
            and tb4.utente = tb0.utente )
        left join siac_rep_var_entrate tb5
         on (tb5.elem_id		=	tb0.elem_id	
            and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
            and tb5.periodo_anno=p_anno
            and tb5.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb6
        on (tb6.elem_id		=	tb0.elem_id
            and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
            and tb6.periodo_anno=p_anno
            and tb6.utente = tb0.utente 	)
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
            (p_anno::INTEGER + 1)::varchar
    from   
        siac_rep_cap_ep tb0 
        left join siac_rep_var_entrate tb1
         on (tb1.elem_id		=	tb0.elem_id	
            and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
            and tb1.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb1.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb2
        on (tb2.elem_id		=	tb0.elem_id
            and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
            and tb2.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb2.utente = tb0.utente )
        left join siac_rep_var_entrate tb3
         on (tb3.elem_id		=	tb0.elem_id	
            and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
            and tb3.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb3.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb4
        on (tb4.elem_id		=	tb0.elem_id
            and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
            and tb4.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb4.utente = tb0.utente )
        left join siac_rep_var_entrate tb5
         on (tb5.elem_id		=	tb0.elem_id	
            and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
            and tb5.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb5.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb6
        on (tb6.elem_id		=	tb0.elem_id
            and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
            and tb6.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb6.utente = tb0.utente 	)
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
            (p_anno::INTEGER + 2)::varchar
        from   
        siac_rep_cap_ep tb0 
        left join siac_rep_var_entrate tb1
         on (tb1.elem_id		=	tb0.elem_id	
            and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
            and tb1.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb1.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb2
        on (tb2.elem_id		=	tb0.elem_id
            and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
            and tb2.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb2.utente = tb0.utente )
        left join siac_rep_var_entrate tb3
         on (tb3.elem_id		=	tb0.elem_id	
            and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
            and tb3.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb3.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb4
        on (tb4.elem_id		=	tb0.elem_id
            and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
            and tb4.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb4.utente = tb0.utente )
        left join siac_rep_var_entrate tb5
         on (tb5.elem_id		=	tb0.elem_id	
            and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
            and tb5.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb5.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb6
        on (tb6.elem_id		=	tb0.elem_id
            and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
            and tb6.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb6.utente = tb0.utente 	);
end if;

-------------------------------------
        

for classifBilRec in

select 	v1.classif_tipo_desc1    		titent_tipo_desc,
       	v1.titolo_id              		titoloe_ID,
       	v1.titolo_code             		titent_code,
       	v1.titolo_desc             		titent_desc,
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
       	tb.elem_desc2     				BIL_ELE_DESC2,
       	tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
	   	COALESCE (tb1.stanziamento_prev_anno,0)				stanziamento_prev_anno,
		COALESCE (tb1.stanziamento_prev_anno1,0)			stanziamento_prev_anno1,
    	COALESCE (tb1.stanziamento_prev_anno2,0)			stanziamento_prev_anno2,
   	 	COALESCE (tb1.residui_presunti,0)					residui_presunti,
    	COALESCE (tb1.previsioni_anno_prec,0)				previsioni_anno_prec,
    	COALESCE (tb1.stanziamento_prev_cassa_anno,0)		stanziamento_prev_cassa_anno,
        COALESCE (var_anno.variazione_aumento_cassa, 0)		variazione_aumento_cassa,
        COALESCE (var_anno.variazione_aumento_residuo, 0)	variazione_aumento_residuo,
        COALESCE (var_anno.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato,
        COALESCE (var_anno.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa,
        COALESCE (var_anno.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo,
        COALESCE (var_anno.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato,
        COALESCE (var_anno1.variazione_aumento_cassa, 0)		variazione_aumento_cassa1,
        COALESCE (var_anno1.variazione_aumento_residuo, 0)	variazione_aumento_residuo1,
        COALESCE (var_anno1.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato1,
        COALESCE (var_anno1.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa1,
        COALESCE (var_anno1.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo1,
        COALESCE (var_anno1.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato1,
        COALESCE (var_anno2.variazione_aumento_cassa, 0)		variazione_aumento_cassa2,
        COALESCE (var_anno2.variazione_aumento_residuo, 0)	variazione_aumento_residuo2,
        COALESCE (var_anno2.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato2,
        COALESCE (var_anno2.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa2,
        COALESCE (var_anno2.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo2,
        COALESCE (var_anno2.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato2
         
from  	siac_rep_tit_tip_cat_riga_anni v1
			FULL  join siac_rep_cap_ep tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					--and tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
            left	join    siac_rep_cap_ep_imp_riga tb1              
            on (tb1.elem_id	=	tb.elem_id
            		AND TB.utente=tb1.utente
                    and tb.utente=user_table)
           left	join    siac_rep_cap_ep_imp_riga tb2  
           			on (tb2.elem_id	=	tb.elem_id
                    	and	tb.utente=user_table
                        and tb2.utente	=	tb.utente)
			left	join  siac_rep_var_entrate_riga var_anno
           			on (var_anno.elem_id	=	tb.elem_id
                    	and var_anno.periodo_anno= annoCapImp
                    	and	tb.utente=user_table
                        and var_anno.utente	=	tb.utente)         
			left	join  siac_rep_var_entrate_riga var_anno1
           			on (var_anno1.elem_id	=	tb.elem_id
                    	and var_anno1.periodo_anno= annoCapImp1
                    	and	tb.utente=user_table
                        and var_anno1.utente	=	tb.utente)  
			left	join  siac_rep_var_entrate_riga var_anno2
           			on (var_anno2.elem_id	=	tb.elem_id
                    	and var_anno2.periodo_anno= annoCapImp2
                    	and	tb.utente=user_table
                        and var_anno2.utente	=	tb.utente)                      
    where v1.utente = user_table   	
			order by titoloe_CODE,tipologia_CODE,categoria_CODE            

loop

/*raise notice 'Dentro loop estrazione capitoli elem_id % ',classifBilRec.bil_ele_id;*/

-- dati capitolo

----titent_tipo_code := classifBilRec.titent_tipo_code;
titent_tipo_desc := classifBilRec.titent_tipo_desc;
titent_code := classifBilRec.titent_code;
titent_desc := classifBilRec.titent_desc;
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
stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;
stanziamento_prev_cassa_anno:=classifBilRec.stanziamento_prev_cassa_anno;


--26/07/2016: sommo gli eventuali valori delle variazioni
stanziamento_prev_anno=stanziamento_prev_anno+classifBilRec.variazione_aumento_stanziato+
            					    classifBilRec.variazione_diminuzione_stanziato;
stanziamento_prev_cassa_anno=stanziamento_prev_cassa_anno+classifBilRec.variazione_aumento_cassa+
            					    classifBilRec.variazione_diminuzione_cassa;                                    
stanziamento_prev_anno1=stanziamento_prev_anno1+classifBilRec.variazione_aumento_stanziato1+
            					    classifBilRec.variazione_diminuzione_stanziato1;
stanziamento_prev_anno2=stanziamento_prev_anno2+classifBilRec.variazione_aumento_stanziato2+
            					    classifBilRec.variazione_diminuzione_stanziato2;


if classifBilRec.variazione_aumento_stanziato <> 0 OR
	classifBilRec.variazione_diminuzione_stanziato <> 0 OR
    classifBilRec.variazione_aumento_cassa <> 0 OR
    classifBilRec.variazione_diminuzione_cassa <> 0 OR    
    classifBilRec.variazione_aumento_stanziato1 <> 0 OR
    classifBilRec.variazione_diminuzione_stanziato1 <> 0 OR
    classifBilRec.variazione_aumento_stanziato2 <> 0 OR
    classifBilRec.variazione_diminuzione_stanziato2 <> 0 OR  
    classifBilRec.variazione_aumento_residuo <> 0 OR
    classifBilRec.variazione_diminuzione_residuo <> 0 THEN
raise notice 'Cap %, ID = %, Tipologia %', bil_ele_code, bil_ele_id, tipologia_code;
raise notice '  variazione_aumento_stanziato = %',classifBilRec.variazione_aumento_stanziato;
raise notice '  variazione_diminuzione_stanziato = %',classifBilRec.variazione_diminuzione_stanziato;
raise notice '  variazione_aumento_cassa = %',classifBilRec.variazione_aumento_cassa;
raise notice '  variazione_diminuzione_cassa = %',classifBilRec.variazione_diminuzione_cassa;
raise notice '  variazione_aumento_stanziato1 = %',classifBilRec.variazione_aumento_stanziato1;
raise notice '  variazione_diminuzione_stanziato1 = %',classifBilRec.variazione_diminuzione_stanziato1;
raise notice '  variazione_aumento_stanziato2 = %',classifBilRec.variazione_aumento_stanziato2;
raise notice '  variazione_diminuzione_stanziato2 = %',classifBilRec.variazione_diminuzione_stanziato2;
raise notice '  variazione_aumento_residuo = %',classifBilRec.variazione_aumento_residuo;
raise notice '  variazione_diminuzione_residuo = %',classifBilRec.variazione_diminuzione_residuo;

end if;    
    

-- importi capitolo

/*raise notice 'record';*/
return next;
bil_anno='';
titent_tipo_code='';
titent_tipo_desc='';
titent_code='';
titent_desc='';
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
stanziamento_prev_cassa_anno:=0;

end loop;

--delete from siac_rep_tit_tip_cat_riga where utente=user_table;
delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;
delete from siac_rep_cap_ep where utente=user_table;
delete from siac_rep_cap_ep_imp where utente=user_table;
delete from siac_rep_cap_ep_imp_riga where utente=user_table;

delete from siac_rep_var_entrate where utente=user_table;

delete from siac_rep_var_entrate_riga where utente=user_table;

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

CREATE OR REPLACE FUNCTION siac."BILR112_Allegato_9_bill_gest_quadr_riass_gen_spese" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_disavanzo boolean,
  p_ele_variazioni varchar,
  p_num_provv_var_peg integer,
  p_anno_provv_var_peg varchar,
  p_tipo_provv_var_peg varchar,
  p_num_provv_var_bil integer,
  p_anno_provv_var_bil varchar,
  p_tipo_provv_var_bil varchar,
  p_code_sac_direz_peg varchar,
  p_code_sac_sett_peg varchar,
  p_code_sac_direz_bil varchar,
  p_code_sac_sett_bil varchar
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
  impegnato_anno numeric,
  impegnato_anno1 numeric,
  impegnato_anno2 numeric,
  stanziamento_fpv_anno_prec numeric,
  stanziamento_fpv_anno numeric,
  stanziamento_fpv_anno1 numeric,
  stanziamento_fpv_anno2 numeric,
  display_error varchar
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
elemTipoCode_UG	varchar;
TipoImpstanzresidui varchar;
anno_bil_impegni	varchar;
tipo_capitolo	varchar;
BIL_ELE_CODE3	varchar;
h_count integer :=0;
importo integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
tipologia_capitolo	varchar;
cat_capitolo	varchar;
sql_query VARCHAR;
strApp VARCHAR;
intApp INTEGER;
-- DAVIDE - SIAC-5202 - oltre 4 variazioni, il codice si sfonda
x_array VARCHAR [];
-- DAVIDE - SIAC-5202 - FINE
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';

contaParVarPeg integer;
contaParVarBil integer;

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
elemTipoCode:='CAP-UG'; -- tipo capitolo previsione
elemTipoCode_UG:='CAP_UG';	--- Capitolo gestione

anno_bil_impegni:= ((p_anno::INTEGER)-1)::VARCHAR;
contaParVarPeg:=0;
contaParVarBil:=0;

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
impegnato_anno=0;
impegnato_anno1=0;
impegnato_anno2=0;
stanziamento_fpv_anno_prec=0;
stanziamento_fpv_anno=0;
stanziamento_fpv_anno1=0;
stanziamento_fpv_anno2=0;
display_error='';

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  -- DAVIDE - SIAC-5202 - oltre 4 variazioni, il codice si sfonda
  x_array = string_to_array(p_ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    --strApp=REPLACE(p_ele_variazioni,',','');
    --raise notice 'VAR: %', strApp;
    intApp = strApp::INTEGER;
  END LOOP;
  -- DAVIDE - SIAC-5202 - FINE

END IF;


/* 26/09/2017: parametri nuovi, controllo che se e' passato uno tra numero/anno/tipo
    	provvedimento di variazione di PEG o di BILANCIO, siano passati anche
        gli altri 2. */
if p_num_provv_var_peg IS NOT  NULL THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if p_anno_provv_var_peg IS NOT  NULL AND p_anno_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if p_tipo_provv_var_peg IS NOT  NULL AND p_tipo_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if contaParVarPeg not in (0,3) then
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di PEG''';
    return next;
    return;        
end if;

if p_num_provv_var_bil IS NOT  NULL THEN
	contaParVarBil=contaParVarBil+1;
end if;
if p_anno_provv_var_bil IS NOT  NULL AND p_anno_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
end if;
if p_tipo_provv_var_bil IS NOT  NULL AND p_tipo_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
end if;
if contaParVarBil not in (0,3) then
	display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di Bilancio''';
    return next;
    return;        
end if;

select fnc_siac_random_user()
into	user_table;

/*
insert into siac_rep_mis_pro_tit_mac_riga_anni
select v.*,user_table from
(SELECT missione_tipo.classif_tipo_desc AS missione_tipo_desc,
    missione.classif_id AS missione_id, missione.classif_code AS missione_code,
    missione.classif_desc AS missione_desc,
    missione.validita_inizio AS missione_validita_inizio,
    missione.validita_fine AS missione_validita_fine,
    programma_tipo.classif_tipo_desc AS programma_tipo_desc,
    programma.classif_id AS programma_id,
    programma.classif_code AS programma_code,
    programma.classif_desc AS programma_desc,
    programma.validita_inizio AS programma_validita_inizio,
    programma.validita_fine AS programma_validita_fine,
    titusc_tipo.classif_tipo_desc AS titusc_tipo_desc,
    titusc.classif_id AS titusc_id, titusc.classif_code AS titusc_code,
    titusc.classif_desc AS titusc_desc,
    titusc.validita_inizio AS titusc_validita_inizio,
    titusc.validita_fine AS titusc_validita_fine,
    macroaggr_tipo.classif_tipo_desc AS macroag_tipo_desc,
    macroaggr.classif_id AS macroag_id, macroaggr.classif_code AS macroag_code,
    macroaggr.classif_desc AS macroag_desc,
    macroaggr.validita_inizio AS macroag_validita_inizio,
    macroaggr.validita_fine AS macroag_validita_fine,
    macroaggr.ente_proprietario_id
FROM siac_d_class_fam missione_fam, siac_t_class_fam_tree missione_tree,
    siac_r_class_fam_tree missione_r_cft, siac_t_class missione,
    siac_d_class_tipo missione_tipo, siac_d_class_tipo programma_tipo,
    siac_t_class programma, siac_d_class_fam titusc_fam,
    siac_t_class_fam_tree titusc_tree, siac_r_class_fam_tree titusc_r_cft,
    siac_t_class titusc, siac_d_class_tipo titusc_tipo,
    siac_d_class_tipo macroaggr_tipo, siac_t_class macroaggr
WHERE missione_fam.classif_fam_desc::text = 'Spesa - MissioniProgrammi'::text
    AND missione_fam.classif_fam_id = missione_tree.classif_fam_id 
    AND missione_tree.classif_fam_tree_id = missione_r_cft.classif_fam_tree_id 
    AND missione_r_cft.classif_id_padre = missione.classif_id 
    AND missione.classif_tipo_id = missione_tipo.classif_tipo_id 
    AND missione_tipo.classif_tipo_code::text = 'MISSIONE'::text 
    AND programma_tipo.classif_tipo_code::text = 'PROGRAMMA'::text 
    AND missione_r_cft.classif_id = programma.classif_id 
    AND programma.classif_tipo_id = programma_tipo.classif_tipo_id 
    AND titusc_fam.classif_fam_desc::text = 'Spesa - TitoliMacroaggregati'::text 
    AND titusc_fam.classif_fam_id = titusc_tree.classif_fam_id 
    AND titusc_tree.classif_fam_tree_id = titusc_r_cft.classif_fam_tree_id 
    AND titusc_r_cft.classif_id_padre = titusc.classif_id 
    AND titusc_tipo.classif_tipo_code::text = 'TITOLO_SPESA'::text 
    AND titusc.classif_tipo_id = titusc_tipo.classif_tipo_id 
    AND macroaggr_tipo.classif_tipo_code::text = 'MACROAGGREGATO'::text 
    AND titusc_r_cft.classif_id = macroaggr.classif_id 
    AND macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id 
    AND missione.ente_proprietario_id = programma.ente_proprietario_id 
    AND programma.ente_proprietario_id = titusc.ente_proprietario_id 
    AND titusc.ente_proprietario_id = macroaggr.ente_proprietario_id
ORDER BY missione.classif_code, programma.classif_code, titusc.classif_code,
    macroaggr.classif_code) v
-------siac_v_mis_pro_tit_macr_anni v 
where v.ente_proprietario_id=p_ente_prop_id 
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.macroag_validita_inizio and
COALESCE(v.macroag_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.missione_validita_inizio and
COALESCE(v.missione_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.programma_validita_inizio and
COALESCE(v.programma_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and 
to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
between  v.titusc_validita_inizio and
COALESCE(v.titusc_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
order by missione_code, programma_code,titusc_code,macroag_code;
*/


-- 06/09/2016: sostituita la query di caricamento struttura del bilancio
--   per migliorare prestazioni
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
    capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
	stato_capitolo.elem_stato_code	=	'VA'								and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and
	-----cat_del_capitolo.elem_cat_code	=	'STD'
    -- 06/09/2016: aggiunto FPVC
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
    where 	capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
    	/*and	capitolo_importi.ente_proprietario_id 	=capitolo_imp_tipo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id 	=capitolo_imp_periodo.ente_proprietario_id
   		and capitolo_importi.ente_proprietario_id	=capitolo_imp_tipo.ente_proprietario_id	
        and capitolo_importi.ente_proprietario_id	=capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=bilancio.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=anno_eserc.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=stato_capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=r_capitolo_stato.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=cat_del_capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id	=r_cat_capitolo.ente_proprietario_id*/
        and	anno_eserc.anno							= p_anno 													
    	and	bilancio.periodo_id						=anno_eserc.periodo_id 								
        and	capitolo.bil_id							=bilancio.bil_id 			 
        and	capitolo.elem_id						=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id					=tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 			= elemTipoCode
        and	capitolo_importi.elem_det_tipo_id		=capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id			=capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)
        and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code	=	'VA'								
        and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
        -- 06/09/2016: aggiunto FPV (che era in query successiva che 
        -- e' stata tolta) e FPVC        		
		and	cat_del_capitolo.elem_cat_code	in ('STD','FSC','FPV','FPVC')								
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
    group by   capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente, cat_del_capitolo.elem_cat_code
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;


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
	where			tb1.elem_id	=	tb2.elem_id								and	
        			tb2.elem_id	=	tb3.elem_id								and
        			tb3.elem_id	=	tb4.elem_id								and
        			tb4.elem_id	=	tb5.elem_id								and
        			tb5.elem_id	=	tb6.elem_id								and
        			tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp	and	tb1.tipo_capitolo 		in ('STD','FSC')
                    AND
        			tb2.periodo_anno = annoCapImp1	AND	tb1.tipo_imp =	tb2.tipo_imp	and	tb2.tipo_capitolo 		in ('STD','FSC')
                    AND
        			tb3.periodo_anno = annoCapImp2	AND	tb2.tipo_imp =	tb3.tipo_imp	and	tb3.tipo_capitolo 	in ('STD','FSC')
                    AND
        			tb4.periodo_anno = tb1.periodo_anno	AND	tb4.tipo_imp = 	TipoImpRes	and	tb4.tipo_capitolo 		in ('STD','FSC')
                    AND
        			tb5.periodo_anno = tb1.periodo_anno	AND	tb5.tipo_imp = 	TipoImpstanzresidui	and	tb5.tipo_capitolo 		in ('STD','FSC')
                    AND
        			tb6.periodo_anno = tb1.periodo_anno	AND	tb6.tipo_imp = 	TipoImpCassa and	tb6.tipo_capitolo 		in ('STD','FSC')
                    and tb1.utente 	= 	tb2.utente	
        			and	tb2.utente	=	tb3.utente
        			and	tb3.utente	=	tb4.utente
        			and	tb4.utente	=	tb5.utente
        			and tb5.utente	=	tb6.utente
        			and	tb6.utente	=	user_table;
                                    
  
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
        AND  -- 06/09/2016: aggiunto FPVC
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
                 
                                       
                    


/*
insert into siac_rep_cap_up_imp_riga
select  tb7.elem_id,      
    	0,
    	0,
    	0,
   	 	0,
    	0,
    	tb6.importo		as		stanziamento_prev_cassa_anno,
        tb7.importo		as		stanziamento_fpv_anno_prec,
  		tb8.importo		as		stanziamento_fpv_anno,
  		tb9.importo		as		stanziamento_fpv_anno1,
  		tb10.importo	as		stanziamento_fpv_anno2,
        tb7.ente_proprietario,
        user_table utente from 
        siac_rep_cap_up_imp tb6,siac_rep_cap_up_imp tb7, siac_rep_cap_up_imp tb8, siac_rep_cap_up_imp tb9,
        siac_rep_cap_up_imp tb10
         where	
        tb6.elem_id	=	tb7.elem_id
        and 	
        tb7.elem_id	=	tb8.elem_id
        and
		tb8.elem_id	=	tb9.elem_id
        and
        tb9.elem_id	=	tb10.elem_id 
        AND
        tb6.periodo_anno = annoCapImp	AND	tb6.tipo_imp = 	TipoImpCassa and	tb6.tipo_capitolo 		= 'FPV'
        AND
    	tb7.periodo_anno = annoCapImp AND	tb7.tipo_imp = 	TipoImpstanzresidui	and	tb7.tipo_capitolo	= 'FPV'
        and
    	tb8.periodo_anno = annoCapImp	AND	tb8.tipo_imp =	TipoImpComp			and	tb8.tipo_capitolo 		= 'FPV'
        AND
        tb9.periodo_anno = annoCapImp1	AND	tb9.tipo_imp =	tb8.tipo_imp 		and	tb9.tipo_capitolo		= 'FPV'
        and
        tb10.periodo_anno = annoCapImp2	AND	tb10.tipo_imp =	tb8.tipo_imp		and	tb10.tipo_capitolo		= 'FPV'
        and tb7.utente 	= 	tb8.utente	
        and	tb8.utente	=	tb9.utente
        and	tb9.utente	=	tb10.utente	
        and	tb10.utente	=	user_table;
        
*/

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
        0,
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
            -----------left JOIN siac_r_bil_elem_rel_tempo tbprec ON tbprec.elem_id = tb.elem_id
    where v1.utente = user_table      
           order by missione_code,programma_code,titusc_code,macroag_code,	BIL_ELE_ID;           

 -------------------------------------
--26/07/2016:
--se sono state specificate delle variazioni cerco i relativi valori
/*25/09/2017: aggiunto anche il controllo relativo ai parametri degli atti.
	Nelle variabili contaParVarPeg e contaParVarBil sono contenuti il numero di parametri 
	riguardanti le delibere PEG e Bilancio; se sono 3 (numero, anno e tipo) significa
    che quel parametro e' stato passato e quindi devo aggiungere il filtro. 
    Aggiunto anche il controllo relativo alle direzione e settori.
    Se p_code_sac_direz_peg e p_code_sac_direz_bil sono uguali a 999 significa che NON
    sono stati specificati. */
--IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') OR
	 contaParVarPeg= 3 OR contaParVarBil = 3 OR p_code_sac_direz_peg <> '999' OR
     p_code_sac_direz_bil <> '999' THEN
	sql_query='
    insert into siac_rep_var_spese
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),
            tipo_elemento.elem_det_tipo_code,  ';
    sql_query=sql_query || ' '''||user_table||''' utente, '; 
    sql_query=sql_query || ' testata_variazione.ente_proprietario_id	,
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
            siac_t_periodo              anno_importo,
            siac_t_bil                  bilancio ';
	if contaParVarPeg = 3 then 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto ,
            siac_d_atto_amm_tipo		tipo_atto,
			siac_r_atto_amm_stato 		r_atto_stato,
	        siac_d_atto_amm_stato 		stato_atto ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto2 ,
            siac_d_atto_amm_tipo		tipo_atto2,
			siac_r_atto_amm_stato 		r_atto_stato2,
	        siac_d_atto_amm_stato 		stato_atto2 ';
    end if;
    IF p_code_sac_direz_peg <> '999'  THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti'; 
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti2'; 
    END IF;                      
    sql_query=sql_query||' where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
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
    if contaParVarPeg = 3 then 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id						=	atto.attoamm_id
    	and		atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
    	and 	atto.attoamm_id										= 	r_atto_stato.attoamm_id
    	and 	r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id_varbil				=	atto2.attoamm_id
    	and		atto2.attoamm_tipo_id								=	tipo_atto2.attoamm_tipo_id
    	and 	atto2.attoamm_id									= 	r_atto_stato2.attoamm_id
    	and 	r_atto_stato2.attoamm_stato_id						=	stato_atto2.attoamm_stato_id ';
    end if;        
    IF p_code_sac_direz_peg <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id =ele_dir_sett_atti.attoamm_id ';
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id_varbil =ele_dir_sett_atti2.attoamm_id ';
    END IF;
    sql_query=sql_query || ' and		testata_variazione.ente_proprietario_id	= ' || p_ente_prop_id|| '
    and		anno_eserc.anno			= 	'''||p_anno||'''
    and		tipologia_stato_var.variazione_stato_tipo_code in (''B'',''G'', ''C'', ''P'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCode|| '''    
    and		tipo_elemento.elem_det_tipo_code	in (''STA'',''SCA'',''STR'') ';
	IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
    	sql_query=sql_query || ' and testata_variazione.variazione_num in ('||p_ele_variazioni||') ';
    end if;
    if contaParVarPeg = 3 then 
    	sql_query=sql_query|| ' AND stato_atto.attoamm_stato_code <> ''ANNULLATO'' 
        and 	atto.attoamm_numero ='||p_num_provv_var_peg||' 
    	and 	atto.attoamm_anno ='''||p_anno_provv_var_peg||'''
    	and		tipo_atto.attoamm_tipo_code='''||p_tipo_provv_var_peg||''' ';
    end if;
   
    if contaParVarBil = 3 then 
    	sql_query=sql_query||' AND stato_atto2.attoamm_stato_code <> ''ANNULLATO'' 
        and 	atto2.attoamm_numero ='||p_num_provv_var_bil||' 
    	and 	atto2.attoamm_anno ='''||p_anno_provv_var_bil||'''
    	and		tipo_atto2.attoamm_tipo_code='''||p_tipo_provv_var_bil||''' ';
    end if;
    IF p_code_sac_direz_peg <> '999' THEN
    	IF p_code_sac_sett_peg = 'T' THEN  -- qualunque settore.
    		sql_query=sql_query||'
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' ';
        ELSIF p_code_sac_sett_peg = '999' THEN -- settore non specificato, quindi atto legato solo ad una direzione.
        	sql_query=sql_query||'
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' 
        		and ele_dir_sett_atti.cod_sett ='''' ';
        ELSE sql_query=sql_query||'    -- = specificati un settore.
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' 
        		and ele_dir_sett_atti.cod_sett ='''||p_code_sac_sett_peg||'''';
        END IF;
    END IF;

    IF p_code_sac_direz_bil <> '999' THEN
    	IF p_code_sac_sett_bil = 'T' THEN  -- qualunque settore.
    		sql_query=sql_query||'
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' ';
        ELSIF p_code_sac_sett_bil = '999' THEN -- settore non specificato, quindi atto legato solo ad una direzione.
        	sql_query=sql_query||'
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' 
        		and ele_dir_sett_atti2.cod_sett ='''' ';
        ELSE sql_query=sql_query||'    -- = specificato un settore.
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' 
        		and ele_dir_sett_atti2.cod_sett ='''||p_code_sac_sett_bil||'''';
        END IF;
    END IF;
    sql_query=sql_query||' and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null ';
    if contaParVarPeg = 3 then 
    	sql_query=sql_query || ' and 	atto.data_cancellazione						is null
    	and 	tipo_atto.data_cancellazione				is null
    	and 	r_atto_stato.data_cancellazione				is null ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query || ' and 	atto2.data_cancellazione		is null
    	and 	tipo_atto2.data_cancellazione				is null
    	and 	r_atto_stato2.data_cancellazione			is null ';
    end if;
    sql_query=sql_query || ' group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                testata_variazione.ente_proprietario_id,
                anno_importo.anno';	     
         
raise notice 'Query: % ',  sql_query;      
EXECUTE sql_query;

RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  

   insert into siac_rep_var_spese_riga
select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        p_anno
from   
	siac_rep_cap_up tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=p_anno
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=p_anno
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=p_anno
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=p_anno
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=p_anno
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=p_anno
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  
   union
     select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
       annocapimp1
from   
	siac_rep_cap_up tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=annocapimp1
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=annocapimp1
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=annocapimp1
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=annocapimp1
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp1
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp1
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  
        union
     select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
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
	siac_rep_cap_up tb0 
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
        where  tb0.utente = user_table    ; 
end if;

-------------------------------------

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
    	COALESCE (t1.stanziamento_prev_anno,0)			stanziamento_prev_anno,
    	COALESCE (t1.stanziamento_prev_anno1,0)			stanziamento_prev_anno1,
    	COALESCE (t1.stanziamento_prev_anno2,0)			stanziamento_prev_anno2,
   	 	COALESCE (t1.stanziamento_prev_res_anno,0)		stanziamento_prev_res_anno,
    	COALESCE (t1.stanziamento_anno_prec,0)			stanziamento_anno_prec,
    	COALESCE (t1.stanziamento_prev_cassa_anno,0)	stanziamento_prev_cassa_anno,
        COALESCE(t1.stanziamento_fpv_anno_prec,0)	stanziamento_fpv_anno_prec,
        COALESCE(t1.stanziamento_fpv_anno,0)	stanziamento_fpv_anno, 
        COALESCE(t1.stanziamento_fpv_anno1,0)	stanziamento_fpv_anno1, 
        COALESCE(t1.stanziamento_fpv_anno2,0)	stanziamento_fpv_anno2 ,
        COALESCE (var_anno.variazione_aumento_cassa, 0)		variazione_aumento_cassa,
        COALESCE (var_anno.variazione_aumento_residuo, 0)	variazione_aumento_residuo,
        COALESCE (var_anno.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato,
        COALESCE (var_anno.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa,
        COALESCE (var_anno.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo,
        COALESCE (var_anno.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato,
        COALESCE (var_anno1.variazione_aumento_cassa, 0)		variazione_aumento_cassa1,
        COALESCE (var_anno1.variazione_aumento_residuo, 0)	variazione_aumento_residuo1,
        COALESCE (var_anno1.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato1,
        COALESCE (var_anno1.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa1,
        COALESCE (var_anno1.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo1,
        COALESCE (var_anno1.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato1,
        COALESCE (var_anno2.variazione_aumento_cassa, 0)		variazione_aumento_cassa2,
        COALESCE (var_anno2.variazione_aumento_residuo, 0)	variazione_aumento_residuo2,
        COALESCE (var_anno2.variazione_aumento_stanziato, 0)	variazione_aumento_stanziato2,
        COALESCE (var_anno2.variazione_diminuzione_cassa, 0)	variazione_diminuzione_cassa2,
        COALESCE (var_anno2.variazione_diminuzione_residuo, 0) variazione_diminuzione_residuo2,
        COALESCE (var_anno2.variazione_diminuzione_stanziato, 0)	variazione_diminuzione_stanziato2                    
from siac_rep_mptm_up_cap_importi t1
		left	join  siac_rep_var_spese_riga var_anno 
           			on (var_anno.elem_id	=	t1.elem_id
                    	and var_anno.periodo_anno= annoCapImp
                    	and	t1.utente=user_table
                        and var_anno.utente	=	t1.utente)         
			left	join  siac_rep_var_spese_riga var_anno1
           			on (var_anno1.elem_id	=	t1.elem_id
                    	and var_anno1.periodo_anno= annoCapImp1
                    	and	t1.utente=user_table
                        and var_anno1.utente	=	t1.utente)  
			left	join  siac_rep_var_spese_riga var_anno2
           			on (var_anno2.elem_id	=	t1.elem_id
                    	and var_anno2.periodo_anno= annoCapImp2
                    	and	t1.utente=user_table
                        and var_anno2.utente	=	t1.utente)   
        order by missione_code,programma_code,titusc_code,macroag_code
          loop
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
          bil_ele_desc2:=classifBilRec.bil_ele_desc2;
          bil_ele_id:=classifBilRec.bil_ele_id;
          bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
          bil_anno:=p_anno;
          stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
          stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
          stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;
          stanziamento_prev_res_anno:=classifBilRec.stanziamento_prev_res_anno;
          stanziamento_anno_prec:=classifBilRec.stanziamento_anno_prec;
          stanziamento_prev_cassa_anno:=classifBilRec.stanziamento_prev_cassa_anno;
          stanziamento_fpv_anno_prec:=classifBilRec.stanziamento_fpv_anno_prec;
          stanziamento_fpv_anno:=classifBilRec.stanziamento_fpv_anno; 
          stanziamento_fpv_anno1:=classifBilRec.stanziamento_fpv_anno1; 
          stanziamento_fpv_anno2:=classifBilRec.stanziamento_fpv_anno2;
          impegnato_anno:=0;
          impegnato_anno1:=0;
          impegnato_anno2=0;

--25/07/2016: sommo gli eventuali valori delle variazioni
--stanziamento_prev_anno=stanziamento_prev_anno+classifBilRec.variazione_aumento_stanziato+
---            					    classifBilRec.variazione_diminuzione_stanziato;
stanziamento_prev_cassa_anno=stanziamento_prev_cassa_anno+classifBilRec.variazione_aumento_cassa+
            					    classifBilRec.variazione_diminuzione_cassa;                                    
--stanziamento_prev_anno1=stanziamento_prev_anno1+classifBilRec.variazione_aumento_stanziato1+
--            					    classifBilRec.variazione_diminuzione_stanziato1;
--stanziamento_prev_anno2=stanziamento_prev_anno2+classifBilRec.variazione_aumento_stanziato2+
--            					    classifBilRec.variazione_diminuzione_stanziato2;
stanziamento_prev_res_anno=stanziamento_prev_res_anno+classifBilRec.variazione_aumento_residuo+
            					    classifBilRec.variazione_diminuzione_residuo;


select b.elem_cat_code into cat_capitolo from siac_r_bil_elem_categoria a, siac_d_bil_elem_categoria b
where a.elem_id=classifBilRec.bil_ele_id 
and a.data_cancellazione is null
and a.validita_fine is null
and a.elem_cat_id=b.elem_cat_id;

--raise notice 'XXXX tipo_categ_capitolo = %', cat_capitolo;
--raise notice 'XXXX elem id = %', classifBilRec.bil_ele_id ;


if cat_capitolo = 'FPV' or cat_capitolo = 'FPVC' then 
stanziamento_fpv_anno=stanziamento_fpv_anno+classifBilRec.variazione_aumento_stanziato+
            					    classifBilRec.variazione_diminuzione_stanziato;

stanziamento_fpv_anno1=stanziamento_fpv_anno1+classifBilRec.variazione_aumento_stanziato1+
            					    classifBilRec.variazione_diminuzione_stanziato1;
stanziamento_fpv_anno2=stanziamento_fpv_anno2+classifBilRec.variazione_aumento_stanziato2+
            					    classifBilRec.variazione_diminuzione_stanziato2;
else

stanziamento_prev_anno=stanziamento_prev_anno+classifBilRec.variazione_aumento_stanziato+
            					    classifBilRec.variazione_diminuzione_stanziato;
	
stanziamento_prev_anno1=stanziamento_prev_anno1+classifBilRec.variazione_aumento_stanziato1+
            					    classifBilRec.variazione_diminuzione_stanziato1;
                                    
stanziamento_prev_anno2=stanziamento_prev_anno2+classifBilRec.variazione_aumento_stanziato2+
            					    classifBilRec.variazione_diminuzione_stanziato2;

end if;


/*          
if classifBilRec.variazione_aumento_stanziato <> 0 OR
	classifBilRec.variazione_diminuzione_stanziato <> 0 OR
    classifBilRec.variazione_aumento_cassa <> 0 OR
    classifBilRec.variazione_diminuzione_cassa <> 0 OR    
    classifBilRec.variazione_aumento_stanziato1 <> 0 OR
    classifBilRec.variazione_diminuzione_stanziato1 <> 0 OR
    classifBilRec.variazione_aumento_stanziato2 <> 0 OR
    classifBilRec.variazione_diminuzione_stanziato2 <> 0 OR  
    classifBilRec.variazione_aumento_residuo <> 0 OR
    classifBilRec.variazione_diminuzione_residuo <> 0 THEN
raise notice 'Cap %, ID = %, Missione = %, Programma = %, Titolo %', bil_ele_code, bil_ele_id, missione_code, programma_code, titusc_code;
raise notice '  variazione_aumento_stanziato = %',classifBilRec.variazione_aumento_stanziato;
raise notice '  variazione_diminuzione_stanziato = %',classifBilRec.variazione_diminuzione_stanziato;
raise notice '  variazione_aumento_cassa = %',classifBilRec.variazione_aumento_cassa;
raise notice '  variazione_diminuzione_cassa = %',classifBilRec.variazione_diminuzione_cassa;
raise notice '  variazione_aumento_stanziato1 = %',classifBilRec.variazione_aumento_stanziato1;
raise notice '  variazione_diminuzione_stanziato1 = %',classifBilRec.variazione_diminuzione_stanziato1;
raise notice '  variazione_aumento_stanziato2 = %',classifBilRec.variazione_aumento_stanziato2;
raise notice '  variazione_diminuzione_stanziato2 = %',classifBilRec.variazione_diminuzione_stanziato2;
raise notice '  variazione_aumento_residuo = %',classifBilRec.variazione_aumento_residuo;
raise notice '  variazione_diminuzione_residuo = %',classifBilRec.variazione_diminuzione_residuo;

end if;            */

-- restituisco il record complessivo
/*raise notice 'record %', classifBilRec.bil_ele_id;
 h_count:=h_count+1;
 raise notice 'n. record %', h_count;*/
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
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_res_anno=0;
stanziamento_anno_prec=0;
stanziamento_prev_cassa_anno=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
impegnato_anno=0;
impegnato_anno1=0;
impegnato_anno2=0;
stanziamento_fpv_anno_prec=0;
stanziamento_fpv_anno=0;
stanziamento_fpv_anno1=0;
stanziamento_fpv_anno2=0;

end loop;

delete from siac_rep_mis_pro_tit_mac_riga_anni where utente=user_table;
delete from siac_rep_cap_up where utente=user_table;
delete from siac_rep_cap_up_imp where utente=user_table;
delete from siac_rep_cap_up_imp_riga where utente=user_table;
delete from siac_rep_mptm_up_cap_importi where utente=user_table;
delete from siac_rep_var_spese  					where utente=user_table;
delete from siac_rep_var_spese_riga  				where utente=user_table;

raise notice 'fine OK';
    exception
    when no_data_found THEN
      raise notice 'nessun dato trovato per struttura bilancio';
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
      RTN_MESSAGGIO:='struttura bilancio altro errore';
      RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
      return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR997_tipo_capitolo_dei_report_variaz" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar,
  p_num_provv_var_peg integer,
  p_anno_provv_var_peg varchar,
  p_tipo_provv_var_peg varchar,
  p_num_provv_var_bil integer,
  p_anno_provv_var_bil varchar,
  p_tipo_provv_var_bil varchar,
  p_code_sac_direz_peg varchar,
  p_code_sac_sett_peg varchar,
  p_code_sac_direz_bil varchar,
  p_code_sac_sett_bil varchar
)
RETURNS TABLE (
  anno_competenza varchar,
  importo numeric,
  descrizione varchar,
  posizione_nel_report integer,
  codice_importo varchar,
  tipo_capitolo_cod varchar
) AS
$body$
DECLARE

classifBilRec record;
tipo_capitolo record;
tipoAvanzo varchar;
tipoDisavanzo varchar;
tipoFpvcc varchar;
tipoFpvsc varchar;
tipoFCassaIni varchar;
tipoFpv varchar;
elemTipoCodeE varchar;
elemTipoCodeS varchar;
RTN_MESSAGGIO varchar(1000):='';
sql_query VARCHAR;
user_table	varchar;
elemTipoCode VARCHAR;
elemCatCode  VARCHAR;
variazione_aumento_stanziato NUMERIC;
variazione_diminuzione_stanziato NUMERIC;
variazione_aumento_cassa NUMERIC;
variazione_diminuzione_cassa NUMERIC;
variazione_aumento_residuo NUMERIC;
variazione_diminuzione_residuo NUMERIC;

--fase_bilancio varchar;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
contaParVarPeg integer;
contaParVarBil integer;

BEGIN

anno_competenza='';
importo=0;
descrizione='';
posizione_nel_report=0;
codice_importo='';
tipoAvanzo='AAM';
tipoDisavanzo='DAM';
tipoFpvcc='FPVCC';
tipoFpvsc='FPVSC';
tipoFCassaIni='FCI';
tipoFpv='FPV'; 
tipo_capitolo_cod='';


elemTipoCodeE:='CAP-EG'; -- tipo capitolo gestione
elemTipoCodeS:='CAP-UG'; -- tipo capitolo gestione

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

elemTipoCode:='CAP-EG'; -- tipo capitolo previsione

variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;

contaParVarPeg:=0;
contaParVarBil:=0;

  /* 22/09/2017: parametri nuovi, controllo che se ?assato uno tra numero/anno/tipo
    	provvedimento di variazione di PEG o di BILANCIO, siano passati anche
        gli altri 2. */
if p_num_provv_var_peg IS NOT  NULL THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if p_anno_provv_var_peg IS NOT  NULL AND p_anno_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if p_tipo_provv_var_peg IS NOT  NULL AND p_tipo_provv_var_peg <> '' THEN
	contaParVarPeg=contaParVarPeg+1;
end if;
if contaParVarPeg not in (0,3) then
	--display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di PEG''';
    return next;
    return;        
end if;

if p_num_provv_var_bil IS NOT  NULL THEN
	contaParVarBil=contaParVarBil+1;
end if;
if p_anno_provv_var_bil IS NOT  NULL AND p_anno_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
end if;
if p_tipo_provv_var_bil IS NOT  NULL AND p_tipo_provv_var_bil <> '' THEN
	contaParVarBil=contaParVarBil+1;
end if;
if contaParVarBil not in (0,3) then
	--display_error='OCCORRE SPECIFICARE TUTTI E 3 I VALORI PER IL PARAMETRO ''Provvedimento di variazione di Bilancio''';
    return next;
    return;        
end if;
select fnc_siac_random_user()
into	user_table;

-------------------------------------
--22/07/2016:
--se sono state specificate delle variazioni cerco i relativi valori


insert into siac_rep_cap_ep
select --cl.classif_id,
  NULL,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente
 from 	--siac_r_bil_elem_class rc,
 		siac_t_bil_elem e,
        --siac_d_class_tipo ct,
		--siac_t_class cl,
        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where-- ct.classif_tipo_code			=	'CATEGORIA'
--and ct.classif_tipo_id				=	cl.classif_tipo_id
--and cl.classif_id					=	rc.classif_id 
--and 
e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code 	= 	elemTipoCodeE
--and e.elem_id						=	rc.elem_id 
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	stato_capitolo.elem_stato_code	=	'VA'
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
--and	cat_del_capitolo.elem_cat_code	=	'STD'
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
--and	rc.data_cancellazione				is null
--and	ct.data_cancellazione 				is null
--and	cl.data_cancellazione 				is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null
--and	now() between rc.validita_inizio and coalesce (rc.validita_fine, now())
and	now() between e.validita_inizio and coalesce (e.validita_fine, now())
and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
--and	now() between ct.validita_inizio and coalesce (ct.validita_fine, now())
--and	now() between cl.validita_inizio and coalesce (cl.validita_fine, now())
and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now());


/* 05/10/2017: aggiunto anche il controllo relativo ai parametri degli atti.
	Nelle variabili contaParVarPeg e contaParVarBil sono contenuti il numero di parametri 
	riguardanti le delibere PEG e Bilancio; se sono 3 (numero, anno e tipo) significa
    che quel parametro ?tato passato e quindi devo aggiungere il filtro. 
    Aggiunto anche il controllo relativo alle direzione e settori.
    Se p_code_sac_direz_peg e p_code_sac_direz_bil sono uguali a 999 significa che NON
    sono stati specificati. */
--IF ele_variazioni IS NOT NULL AND ele_variazioni <> '' THEN
IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') OR
	 contaParVarPeg= 3 OR contaParVarBil = 3 OR p_code_sac_direz_peg <> '999' OR
     p_code_sac_direz_bil <> '999' THEN
	sql_query='
    insert into siac_rep_var_entrate
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),
            tipo_elemento.elem_det_tipo_code,  ';
    sql_query=sql_query || ' '''||user_table||''' utente, '; 
    sql_query=sql_query || ' testata_variazione.ente_proprietario_id	,
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
            siac_t_periodo              anno_importo,
            siac_t_bil                  bilancio  ';
    if contaParVarPeg = 3 then 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto ,
            siac_d_atto_amm_tipo		tipo_atto,
			siac_r_atto_amm_stato 		r_atto_stato,
	        siac_d_atto_amm_stato 		stato_atto ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto2 ,
            siac_d_atto_amm_tipo		tipo_atto2,
			siac_r_atto_amm_stato 		r_atto_stato2,
	        siac_d_atto_amm_stato 		stato_atto2 ';
    end if;
    IF p_code_sac_direz_peg <> '999'  THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti'; 
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti2'; 
    END IF;
    sql_query=sql_query||'  where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
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
    if contaParVarPeg = 3 then 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id						=	atto.attoamm_id
    	and		atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
    	and 	atto.attoamm_id										= 	r_atto_stato.attoamm_id
    	and 	r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id_varbil				=	atto2.attoamm_id
    	and		atto2.attoamm_tipo_id								=	tipo_atto2.attoamm_tipo_id
    	and 	atto2.attoamm_id									= 	r_atto_stato2.attoamm_id
    	and 	r_atto_stato2.attoamm_stato_id						=	stato_atto2.attoamm_stato_id ';
    end if;
        
    IF p_code_sac_direz_peg <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id =ele_dir_sett_atti.attoamm_id ';
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id_varbil =ele_dir_sett_atti2.attoamm_id ';
    END IF;
    sql_query=sql_query || ' and		testata_variazione.ente_proprietario_id				= ' || p_ente_prop_id;
    sql_query=sql_query || ' and		anno_eserc.anno			= 	'''||p_anno||'''
    and		tipologia_stato_var.variazione_stato_tipo_code in (''B'',''G'', ''C'', ''P'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCodeE|| '''    
    and		tipo_elemento.elem_det_tipo_code	in (''STA'',''SCA'',''STR'') ';
    
    IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
    	sql_query=sql_query || ' and testata_variazione.variazione_num in ('||p_ele_variazioni||') ';
    end if;
    if contaParVarPeg = 3 then 
    	sql_query=sql_query||' AND stato_atto.attoamm_stato_code = ''DEFINITIVO'' 
        and 	atto.attoamm_numero ='||p_num_provv_var_peg||' 
    	and 	atto.attoamm_anno ='''||p_anno_provv_var_peg||'''
    	and		tipo_atto.attoamm_tipo_code='''||p_tipo_provv_var_peg||''' ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||' AND stato_atto2.attoamm_stato_code = ''DEFINITIVO'' 
        and 	atto2.attoamm_numero ='||p_num_provv_var_bil||' 
    	and 	atto2.attoamm_anno ='''||p_anno_provv_var_bil||'''
    	and		tipo_atto2.attoamm_tipo_code='''||p_tipo_provv_var_bil||''' ';
    end if;
    IF p_code_sac_direz_peg <> '999' THEN
    	IF p_code_sac_sett_peg = 'T' THEN  -- qualunque settore.
    		sql_query=sql_query||'
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' ';
        ELSIF p_code_sac_sett_peg = '999' THEN -- settore non specificato, quindi atto legato solo ad una direzione.
        	sql_query=sql_query||'
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' 
        		and ele_dir_sett_atti.cod_sett ='''' ';
        ELSE sql_query=sql_query||'    -- = specificati un settore.
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' 
        		and ele_dir_sett_atti.cod_sett ='''||p_code_sac_sett_peg||'''';
        END IF;
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	IF p_code_sac_sett_bil = 'T' THEN  -- qualunque settore.
    		sql_query=sql_query||'
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' ';
        ELSIF p_code_sac_sett_bil = '999' THEN -- settore non specificato, quindi atto legato solo ad una direzione.
        	sql_query=sql_query||'
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' 
        		and ele_dir_sett_atti2.cod_sett ='''' ';
        ELSE sql_query=sql_query||'    -- = specificato un settore.
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' 
        		and ele_dir_sett_atti2.cod_sett ='''||p_code_sac_sett_bil||'''';
        END IF;
    END IF;
    sql_query=sql_query||' and		r_variazione_stato.data_cancellazione		is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null ';
    if contaParVarPeg = 3 then 
    	sql_query=sql_query || ' and 	atto.data_cancellazione						is null
    	and 	tipo_atto.data_cancellazione				is null
    	and 	r_atto_stato.data_cancellazione				is null ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query || ' and 	atto2.data_cancellazione		is null
    	and 	tipo_atto2.data_cancellazione				is null
    	and 	r_atto_stato2.data_cancellazione			is null ';
    end if;
    sql_query=sql_query || ' group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                testata_variazione.ente_proprietario_id,
                anno_importo.anno';	     
         
raise notice 'Query Var Entrate: % ',  sql_query;      
EXECUTE sql_query;

RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  

    insert into siac_rep_var_entrate_riga
    select  tb0.elem_id,     
            tb1.importo   as 		variazione_aumento_stanziato,
            tb2.importo   as 		variazione_diminuzione_stanziato,
            tb3.importo   as 		variazione_aumento_cassa,
            tb4.importo   as 		variazione_diminuzione_cassa,
            tb5.importo   as 		variazione_aumento_residuo,
            tb6.importo   as 		variazione_diminuzione_residuo,
            user_table utente,
            p_ente_prop_id,
            p_anno
    from   
        siac_rep_cap_ep tb0 
        left join siac_rep_var_entrate tb1
         on (tb1.elem_id		=	tb0.elem_id	
            and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
            and tb1.periodo_anno=p_anno
            and tb1.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb2
        on (tb2.elem_id		=	tb0.elem_id
            and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
            and tb2.periodo_anno=p_anno
            and tb2.utente = tb0.utente )
        left join siac_rep_var_entrate tb3
         on (tb3.elem_id		=	tb0.elem_id	
            and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
            and tb3.periodo_anno=p_anno
            and tb3.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb4
        on (tb4.elem_id		=	tb0.elem_id
            and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
            and tb4.periodo_anno=p_anno
            and tb4.utente = tb0.utente )
        left join siac_rep_var_entrate tb5
         on (tb5.elem_id		=	tb0.elem_id	
            and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
            and tb5.periodo_anno=p_anno
            and tb5.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb6
        on (tb6.elem_id		=	tb0.elem_id
            and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
            and tb6.periodo_anno=p_anno
            and tb6.utente = tb0.utente 	)
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
            (p_anno::INTEGER + 1)::varchar
    from   
        siac_rep_cap_ep tb0 
        left join siac_rep_var_entrate tb1
         on (tb1.elem_id		=	tb0.elem_id	
            and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
            and tb1.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb1.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb2
        on (tb2.elem_id		=	tb0.elem_id
            and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
            and tb2.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb2.utente = tb0.utente )
        left join siac_rep_var_entrate tb3
         on (tb3.elem_id		=	tb0.elem_id	
            and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
            and tb3.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb3.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb4
        on (tb4.elem_id		=	tb0.elem_id
            and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
            and tb4.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb4.utente = tb0.utente )
        left join siac_rep_var_entrate tb5
         on (tb5.elem_id		=	tb0.elem_id	
            and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
            and tb5.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb5.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb6
        on (tb6.elem_id		=	tb0.elem_id
            and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
            and tb6.periodo_anno= (p_anno::INTEGER + 1)::varchar
            and tb6.utente = tb0.utente 	)
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
            (p_anno::INTEGER + 2)::varchar
        from   
        siac_rep_cap_ep tb0 
        left join siac_rep_var_entrate tb1
         on (tb1.elem_id		=	tb0.elem_id	
            and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
            and tb1.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb1.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb2
        on (tb2.elem_id		=	tb0.elem_id
            and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
            and tb2.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb2.utente = tb0.utente )
        left join siac_rep_var_entrate tb3
         on (tb3.elem_id		=	tb0.elem_id	
            and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
            and tb3.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb3.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb4
        on (tb4.elem_id		=	tb0.elem_id
            and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
            and tb4.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb4.utente = tb0.utente )
        left join siac_rep_var_entrate tb5
         on (tb5.elem_id		=	tb0.elem_id	
            and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
            and tb5.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb5.utente = tb0.utente ) 
        left join siac_rep_var_entrate tb6
        on (tb6.elem_id		=	tb0.elem_id
            and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
            and tb6.periodo_anno= (p_anno::INTEGER + 2)::varchar
            and tb6.utente = tb0.utente 	);



insert into siac_rep_cap_ug 
select 	NULL, --programma.classif_id,
		NULL, --macroaggr.classif_id,
        anno_eserc.anno anno_bilancio,
       	capitolo.*,
        ' ',
       user_table utente
from siac_t_bil bilancio,
	 siac_t_periodo anno_eserc,
     --siac_d_class_tipo programma_tipo,
     --siac_t_class programma,
    -- siac_d_class_tipo macroaggr_tipo,
     --siac_t_class macroaggr,
	 siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     --siac_r_bil_elem_class r_capitolo_programma,
     --siac_r_bil_elem_class r_capitolo_macroaggr, 
	 siac_d_bil_elem_stato stato_capitolo, 
     siac_r_bil_elem_stato r_capitolo_stato,
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo
where 
	--programma_tipo.classif_tipo_code='PROGRAMMA' 							and		
    --programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
   -- programma.classif_id=r_capitolo_programma.classif_id					and
    --macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						and
    --macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    --macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and
    capitolo.ente_proprietario_id=p_ente_prop_id      						and
   	anno_eserc.anno= p_anno 												and
    bilancio.periodo_id=anno_eserc.periodo_id 								and
    capitolo.bil_id=bilancio.bil_id 										and
   	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    tipo_elemento.elem_tipo_code = elemTipoCodeS						     	and 
    --capitolo.elem_id=r_capitolo_programma.elem_id							and
    --capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
    capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
	stato_capitolo.elem_stato_code	=	'VA'								and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		
    ------cat_del_capitolo.elem_cat_code	=	'STD'	
	--cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC')
    and	bilancio.data_cancellazione 				is null
	and	anno_eserc.data_cancellazione 				is null
   	--and	programma_tipo.data_cancellazione 			is null
    --and	programma.data_cancellazione 				is null
    --and	macroaggr_tipo.data_cancellazione 			is null
    --and	macroaggr.data_cancellazione 				is null
	and	capitolo.data_cancellazione 				is null
	and	tipo_elemento.data_cancellazione 			is null
    --and	r_capitolo_programma.data_cancellazione 	is null
   	--and	r_capitolo_macroaggr.data_cancellazione 	is null 
	and	stato_capitolo.data_cancellazione 			is null 
    and	r_capitolo_stato.data_cancellazione 		is null
	and	cat_del_capitolo.data_cancellazione 		is null
    and	r_cat_capitolo.data_cancellazione 			is null;	
    
    
sql_query='
    insert into siac_rep_var_spese
    select	dettaglio_variazione.elem_id,
            sum(dettaglio_variazione.elem_det_importo),
            tipo_elemento.elem_det_tipo_code,  ';
    sql_query=sql_query || ' '''||user_table||''' utente, '; 
    sql_query=sql_query || ' testata_variazione.ente_proprietario_id	,
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
            siac_t_periodo              anno_importo,
            siac_t_bil                  bilancio  ';
	if contaParVarPeg = 3 then 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto ,
            siac_d_atto_amm_tipo		tipo_atto,
			siac_r_atto_amm_stato 		r_atto_stato,
	        siac_d_atto_amm_stato 		stato_atto ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||'        	
        	,siac_t_atto_amm 			atto2 ,
            siac_d_atto_amm_tipo		tipo_atto2,
			siac_r_atto_amm_stato 		r_atto_stato2,
	        siac_d_atto_amm_stato 		stato_atto2 ';
    end if;
    IF p_code_sac_direz_peg <> '999'  THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti'; 
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||' 
    		,  "fnc_elenco_direzioni_settori_atti"('||p_ente_prop_id||') ele_dir_sett_atti2'; 
    END IF;                      
    
    sql_query=sql_query||' where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
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
    if contaParVarPeg = 3 then 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id						=	atto.attoamm_id
    	and		atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
    	and 	atto.attoamm_id										= 	r_atto_stato.attoamm_id
    	and 	r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query||' 
        and		r_variazione_stato.attoamm_id_varbil				=	atto2.attoamm_id
    	and		atto2.attoamm_tipo_id								=	tipo_atto2.attoamm_tipo_id
    	and 	atto2.attoamm_id									= 	r_atto_stato2.attoamm_id
    	and 	r_atto_stato2.attoamm_stato_id						=	stato_atto2.attoamm_stato_id ';
    end if;
        
    IF p_code_sac_direz_peg <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id =ele_dir_sett_atti.attoamm_id ';
    END IF;
    IF p_code_sac_direz_bil <> '999' THEN
    	sql_query=sql_query||'
        	and r_variazione_stato.attoamm_id_varbil =ele_dir_sett_atti2.attoamm_id ';
    END IF;
    sql_query=sql_query || ' and		testata_variazione.ente_proprietario_id	= ' || p_ente_prop_id;
    sql_query=sql_query || ' and		anno_eserc.anno			= 	'''||p_anno||'''
    and		tipologia_stato_var.variazione_stato_tipo_code in (''B'',''G'', ''C'', ''P'')
    and		tipo_capitolo.elem_tipo_code = ''' || elemTipoCodeS|| '''    
    and		tipo_elemento.elem_det_tipo_code	in (''STA'',''SCA'',''STR'') ';
    
IF (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
    	sql_query=sql_query || ' and testata_variazione.variazione_num in ('||p_ele_variazioni||') ';
    end if;
    if contaParVarPeg = 3 then 
    	sql_query=sql_query|| ' AND stato_atto.attoamm_stato_code = ''DEFINITIVO'' 
        and 	atto.attoamm_numero ='||p_num_provv_var_peg||' 
    	and 	atto.attoamm_anno ='''||p_anno_provv_var_peg||'''
    	and		tipo_atto.attoamm_tipo_code='''||p_tipo_provv_var_peg||''' ';
    end if;
   
    if contaParVarBil = 3 then 
    	sql_query=sql_query||' AND stato_atto2.attoamm_stato_code = ''DEFINITIVO'' 
        and 	atto2.attoamm_numero ='||p_num_provv_var_bil||' 
    	and 	atto2.attoamm_anno ='''||p_anno_provv_var_bil||'''
    	and		tipo_atto2.attoamm_tipo_code='''||p_tipo_provv_var_bil||''' ';
    end if;
    
    IF p_code_sac_direz_peg <> '999' THEN
    	IF p_code_sac_sett_peg = 'T' THEN  -- qualunque settore.
    		sql_query=sql_query||'
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' ';
        ELSIF p_code_sac_sett_peg = '999' THEN -- settore non specificato, quindi atto legato solo ad una direzione.
        	sql_query=sql_query||'
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' 
        		and ele_dir_sett_atti.cod_sett ='''' ';
        ELSE sql_query=sql_query||'    -- = specificati un settore.
        		and ele_dir_sett_atti.cod_direz = '''||p_code_sac_direz_peg||''' 
        		and ele_dir_sett_atti.cod_sett ='''||p_code_sac_sett_peg||'''';
        END IF;
    END IF;

    IF p_code_sac_direz_bil <> '999' THEN
    	IF p_code_sac_sett_bil = 'T' THEN  -- qualunque settore.
    		sql_query=sql_query||'
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' ';
        ELSIF p_code_sac_sett_bil = '999' THEN -- settore non specificato, quindi atto legato solo ad una direzione.
        	sql_query=sql_query||'
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' 
        		and ele_dir_sett_atti2.cod_sett ='''' ';
        ELSE sql_query=sql_query||'    -- = specificato un settore.
        		and ele_dir_sett_atti2.cod_direz = '''||p_code_sac_direz_bil||''' 
        		and ele_dir_sett_atti2.cod_sett ='''||p_code_sac_sett_bil||'''';
        END IF;
    END IF;
    
    sql_query=sql_query||' and		r_variazione_stato.data_cancellazione	is null
    and		testata_variazione.data_cancellazione		is null
    and		tipologia_variazione.data_cancellazione		is null
    and		tipologia_stato_var.data_cancellazione		is null
    and 	dettaglio_variazione.data_cancellazione		is null
    and 	capitolo.data_cancellazione					is null
    and		tipo_capitolo.data_cancellazione			is null
    and		tipo_elemento.data_cancellazione			is null ';
    if contaParVarPeg = 3 then 
    	sql_query=sql_query || ' and 	atto.data_cancellazione						is null
    	and 	tipo_atto.data_cancellazione				is null
    	and 	r_atto_stato.data_cancellazione				is null ';
    end if;
    if contaParVarBil = 3 then 
    	sql_query=sql_query || ' and 	atto2.data_cancellazione		is null
    	and 	tipo_atto2.data_cancellazione				is null
    	and 	r_atto_stato2.data_cancellazione			is null ';
    end if;
    sql_query=sql_query || ' group by 	dettaglio_variazione.elem_id,
                tipo_elemento.elem_det_tipo_code, 
                utente,
                testata_variazione.ente_proprietario_id,
                anno_importo.anno';	     
         
raise notice 'Query: % ',  sql_query;      
EXECUTE sql_query;


   insert into siac_rep_var_spese_riga
select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        p_anno
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=p_anno
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=p_anno
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=p_anno
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=p_anno
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=p_anno
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=p_anno
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  
   union
     select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
       annocapimp1
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=annocapimp1
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=annocapimp1
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=annocapimp1
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=annocapimp1
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=annocapimp1
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=annocapimp1
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  
        union
     select  tb0.elem_id,
 /*
  		sum (tb1.importo)   as 		variazione_aumento_stanziato,
        sum (tb2.importo)   as 		variazione_diminuzione_stanziato,
        sum (tb3.importo)   as 		variazione_aumento_cassa,
        sum (tb4.importo)   as 		variazione_diminuzione_cassa,
        sum (tb5.importo)   as 		variazione_aumento_residuo,
        sum (tb6.importo)   as 		variazione_diminuzione_residuo,
*/        
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
        where  tb0.utente = user_table    ; 
        
        
end if;

    
-------------------------------------
/*
for tipo_capitolo in
        select t0.anno_competenza, t0.importo, t0.descrizione,
        		t0.posizione_nel_report, t0.codice_importo, t0.tipo_capitolo_cod,
                sum (t1.variazione_aumento_stanziato) variazione_aumento_stanziato,
                sum (t1.variazione_diminuzione_stanziato) variazione_diminuzione_stanziato,
                sum (t1.variazione_aumento_cassa) variazione_aumento_cassa,
                sum (t1.variazione_diminuzione_cassa) variazione_diminuzione_cassa,
                sum (t1.variazione_aumento_residuo) variazione_aumento_residuo,
                sum (t1.variazione_diminuzione_residuo)   variazione_diminuzione_residuo                                                                                              
			from "BILR997_tipo_capitolo_dei_report" (p_ente_prop_id, p_anno) t0,
            	siac_rep_var_entrate_riga t1,
                siac_d_bil_elem_categoria cat_del_capitolo,
    			siac_r_bil_elem_categoria r_cat_capitolo
        	where r_cat_capitolo.elem_cat_id=cat_del_capitolo.elem_cat_id
            	and r_cat_capitolo.elem_id=t1.elem_id
                and cat_del_capitolo.elem_cat_code=t0.codice_importo
                and t1.periodo_anno=t0.anno_competenza
                and t1.utente=user_table
            group by t0.anno_competenza, t0.importo, t0.descrizione,
        		t0.posizione_nel_report, t0.codice_importo, t0.tipo_capitolo_cod
                */
-- INC000001599997 Inizio
/*for tipo_capitolo in
        select t0.*               
			from "BILR997_tipo_capitolo_dei_report" (p_ente_prop_id, p_anno) t0
            	ORDER BY t0.anno_competenza
loop*/
for tipo_capitolo in
        select t0.*               
			from "BILR000_tipo_capitolo_dei_report" (p_ente_prop_id, p_anno, 'G') t0
            	ORDER BY t0.anno_competenza
loop
-- INC000001599997 Fine

importo = tipo_capitolo.importo;
elemCatCode= tipo_capitolo.codice_importo;

IF tipo_capitolo.tipo_capitolo_cod ='CAP-EG' THEN  
	--Cerco i dati delle eventuali variazioni di spesa
--raise notice 'codice importo =%', tipo_capitolo.codice_importo;      
	
--16/03/2017: nel caso di capitoli FPV di entrata devo sommare gli importi
--	dei capitoli FPVSC e FPVCC.
		if tipo_capitolo.codice_importo = 'FPV' then
              --raise notice 'tipo_capitolo.codice_importo=%', variazione_diminuzione_stanziato;
              select      'FPV' elem_cat_code , 
                  coalesce (sum (t1.variazione_aumento_stanziato),0) variazione_aumento_stanziato,
                  coalesce (sum (t1.variazione_diminuzione_stanziato),0) variazione_diminuzione_stanziato,
                  coalesce (sum (t1.variazione_aumento_cassa),0) variazione_aumento_cassa,
                  coalesce (sum (t1.variazione_diminuzione_cassa),0) variazione_diminuzione_cassa,
                  coalesce (sum (t1.variazione_aumento_residuo),0) variazione_aumento_residuo,
                  coalesce (sum (t1.variazione_diminuzione_residuo),0) variazione_diminuzione_residuo                                                                                           
              into elemCatCode,variazione_aumento_stanziato, variazione_diminuzione_stanziato,
                  variazione_aumento_cassa, variazione_diminuzione_cassa,variazione_aumento_residuo,
              variazione_diminuzione_residuo 
              from siac_rep_var_entrate_riga t1,
                  siac_r_bil_elem_categoria r_cat_capitolo,
                  siac_d_bil_elem_categoria cat_del_capitolo            
              WHERE  r_cat_capitolo.elem_id=t1.elem_id
                  AND r_cat_capitolo.elem_cat_id=cat_del_capitolo.elem_cat_id
                  AND t1.utente=user_table
                  AND cat_del_capitolo.elem_cat_code in (tipoFpvcc, tipoFpvsc)
                  AND r_cat_capitolo.data_cancellazione IS NULL
                  AND cat_del_capitolo.data_cancellazione IS NULL
                  AND t1.periodo_anno = tipo_capitolo.anno_competenza
             -- 17/07/2017: commentata la group by per jira SIAC-5105
             	--group by  elem_cat_code  
             ;             
            IF NOT FOUND THEN
                  variazione_aumento_stanziato=0;
                  variazione_diminuzione_stanziato=0;
                  variazione_aumento_cassa=0;
                  variazione_diminuzione_cassa=0;
                  variazione_aumento_residuo=0;
                  variazione_diminuzione_residuo=0;
            end if;
            
            raise notice 'variazione_aumento_stanziato=%', variazione_aumento_stanziato;
            raise notice 'variazione_diminuzione_stanziato=%', variazione_diminuzione_stanziato;

            importo = tipo_capitolo.importo+variazione_aumento_stanziato+variazione_diminuzione_stanziato; 
            else 


               select      cat_del_capitolo.elem_cat_code,
                    coalesce (sum (t1.variazione_aumento_stanziato),0) variazione_aumento_stanziato,
                    coalesce (sum (t1.variazione_diminuzione_stanziato),0) variazione_diminuzione_stanziato,
                    coalesce (sum (t1.variazione_aumento_cassa),0) variazione_aumento_cassa,
                    coalesce (sum (t1.variazione_diminuzione_cassa),0) variazione_diminuzione_cassa,
                    coalesce (sum (t1.variazione_aumento_residuo),0) variazione_aumento_residuo,
                    coalesce (sum (t1.variazione_diminuzione_residuo),0) variazione_diminuzione_residuo                                                                                           
                into elemCatCode,variazione_aumento_stanziato, variazione_diminuzione_stanziato,
                    variazione_aumento_cassa, variazione_diminuzione_cassa,variazione_aumento_residuo,
                variazione_diminuzione_residuo 
                from siac_rep_var_entrate_riga t1,
                    siac_r_bil_elem_categoria r_cat_capitolo,
                    siac_d_bil_elem_categoria cat_del_capitolo            
                WHERE  r_cat_capitolo.elem_id=t1.elem_id
                    AND r_cat_capitolo.elem_cat_id=cat_del_capitolo.elem_cat_id
                    AND t1.utente=user_table
                    AND cat_del_capitolo.elem_cat_code=tipo_capitolo.codice_importo
                    AND r_cat_capitolo.data_cancellazione IS NULL
                    AND cat_del_capitolo.data_cancellazione IS NULL
                    AND t1.periodo_anno = tipo_capitolo.anno_competenza
                group by cat_del_capitolo.elem_cat_code   ; 
                
                IF NOT FOUND THEN
                  variazione_aumento_stanziato=0;
                  variazione_diminuzione_stanziato=0;
                  variazione_aumento_cassa=0;
                  variazione_diminuzione_cassa=0;
                  variazione_aumento_residuo=0;
                  variazione_diminuzione_residuo=0;
                ELSE
                 -- raise notice 'elemCatCode=%', elemCatCode;
                
                  
                  /*IF elemCatCode = tipoAvanzo OR elemCatCode= tipoDisavanzo OR 
                      elemCatCode=tipoFpvcc OR elemCatCode=tipoFpvsc  THEN            
                          importo = tipo_capitolo.importo+variazione_aumento_stanziato+variazione_diminuzione_stanziato;
                  ELSIF elemCatCode = tipoFCassaIni THEN
                      importo =importo+variazione_aumento_cassa+variazione_diminuzione_cassa;              	
                  END IF;    */ 
                  
                  IF elemCatCode = tipoFCassaIni THEN
                      importo =tipo_capitolo.importo+variazione_aumento_cassa+variazione_diminuzione_cassa;  
                  ELSE         
                      importo = tipo_capitolo.importo+variazione_aumento_stanziato+variazione_diminuzione_stanziato;   	
                  END IF;
              
            end if;  
                  
            END IF;     
            
ELSE  --Cerco i dati delle eventuali variazioni di spesa
--raise notice 'codice importo =%', tipo_capitolo.codice_importo;
	select      cat_del_capitolo.elem_cat_code,
			    coalesce (sum (t1.variazione_aumento_stanziato),0) variazione_aumento_stanziato,
                coalesce (sum (t1.variazione_diminuzione_stanziato),0) variazione_diminuzione_stanziato,
                coalesce (sum (t1.variazione_aumento_cassa),0) variazione_aumento_cassa,
                coalesce (sum (t1.variazione_diminuzione_cassa),0) variazione_diminuzione_cassa,
                coalesce (sum (t1.variazione_aumento_residuo),0) variazione_aumento_residuo,
                coalesce (sum (t1.variazione_diminuzione_residuo),0) variazione_diminuzione_residuo                                                                                               
			into elemCatCode,variazione_aumento_stanziato, variazione_diminuzione_stanziato,
            	variazione_aumento_cassa, variazione_diminuzione_cassa,variazione_aumento_residuo,
			variazione_diminuzione_residuo 
            from siac_rep_var_spese_riga t1,
            	siac_r_bil_elem_categoria r_cat_capitolo,
                siac_d_bil_elem_categoria cat_del_capitolo            
            WHERE  r_cat_capitolo.elem_id=t1.elem_id
            	AND r_cat_capitolo.elem_cat_id=cat_del_capitolo.elem_cat_id
            	AND t1.utente=user_table
                AND cat_del_capitolo.elem_cat_code=tipo_capitolo.codice_importo
                AND r_cat_capitolo.data_cancellazione IS NULL
                AND cat_del_capitolo.data_cancellazione IS NULL
                AND t1.periodo_anno = tipo_capitolo.anno_competenza
            group by cat_del_capitolo.elem_cat_code   ; 
            IF NOT FOUND THEN
              variazione_aumento_stanziato=0;
              variazione_diminuzione_stanziato=0;
              variazione_aumento_cassa=0;
              variazione_diminuzione_cassa=0;
              variazione_aumento_residuo=0;
              variazione_diminuzione_residuo=0;
            ELSE
            --raise notice 'elemCatCode=%', elemCatCode;
             /* IF elemCatCode = tipoAvanzo OR elemCatCode= tipoDisavanzo OR 
                  elemCatCode=tipoFpvcc OR elemCatCode=tipoFpvsc OR 
                  elemCatCode= tipoFpvcc OR elemCatCode =tipoFpvsc THEN            
                      importo = tipo_capitolo.importo+variazione_aumento_stanziato+variazione_diminuzione_stanziato;
              ELSIF elemCatCode = tipoFCassaIni THEN
                  importo = importo+variazione_aumento_cassa+variazione_diminuzione_cassa;
              END IF; */  
              importo = tipo_capitolo.importo+variazione_aumento_stanziato+variazione_diminuzione_stanziato;               
            END IF;                    
END IF;
            
--raise notice 'anno_competenza=%', tipo_capitolo.anno_competenza;
--raise notice 'codice_importo=%', tipo_capitolo.codice_importo;
--raise notice 'importo=%', tipo_capitolo.importo;
--raise notice 'variazione_aumento_stanziato=%', variazione_aumento_stanziato;
--raise notice 'variazione_diminuzione_stanziato=%', variazione_diminuzione_stanziato;
--raise notice 'variazione_aumento_cassa=%', variazione_aumento_cassa;
--raise notice 'variazione_diminuzione_cassa=%', variazione_diminuzione_cassa;
--raise notice 'variazione_aumento_residuo=%', variazione_aumento_residuo;
--raise notice 'variazione_diminuzione_residuo=%', variazione_diminuzione_residuo;


anno_competenza = tipo_capitolo.anno_competenza;
descrizione = tipo_capitolo.descrizione;
posizione_nel_report = tipo_capitolo.posizione_nel_report;
codice_importo = tipo_capitolo.codice_importo;
tipo_capitolo_cod = tipo_capitolo.tipo_capitolo_cod;

return next;

variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;
anno_competenza = '';
descrizione = '';
posizione_nel_report = 0;
codice_importo = '';
tipo_capitolo_cod = '';
importo=0;

end loop;


delete from siac_rep_cap_ep where utente=user_table;
delete from siac_rep_cap_ug where utente=user_table;

delete from siac_rep_var_entrate where utente=user_table;

delete from siac_rep_var_entrate_riga where utente=user_table;

delete from siac_rep_var_spese where utente=user_table;
delete from siac_rep_var_spese_riga where utente=user_table;


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
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



CREATE OR REPLACE FUNCTION siac.fnc_elenco_direzioni_settori_atti (
  ente_proprietario_id_in integer
)
RETURNS TABLE (
  cod_direz varchar,
  desc_direz varchar,
  cod_sett varchar,
  desc_sett varchar,
  attoamm_id integer
) AS
$body$
DECLARE
RTN_MESSAGGIO varchar;
ndc record;
sqlQuery VARCHAR;

BEGIN 


RTN_MESSAGGIO:='Errore generico';


sqlQuery='with 
ele_settori as (
SELECT   t_class2.classif_code cod_direz, t_class2.classif_desc  desc_direz,
 t_class.classif_code cod_sett, t_class.classif_desc  desc_sett, 
	t_class.classif_id
            from siac_r_class_fam_tree r_class_fam_tree,
                siac_t_class			t_class,
                siac_d_class_tipo		d_class_tipo,
                siac_t_class			t_class2               
        where                        
             t_class.classif_id 					= 	r_class_fam_tree.classif_id
            and d_class_tipo.classif_tipo_id		=	t_class.classif_tipo_id
            and t_class2.classif_id = r_class_fam_tree.classif_id_padre            
           --SETTORE
           AND d_class_tipo.classif_tipo_code=''CDC''
           and t_class.ente_proprietario_id='||ente_proprietario_id_in||'            
             AND t_class.data_cancellazione is NULL
             AND d_class_tipo.data_cancellazione is NULL             
             and r_class_fam_tree.data_cancellazione is NULL
                        
            and (t_class.validita_inizio <=now() AND
            	COALESCE(t_class.validita_fine, now()) >=now())  
 ),
 ele_direzioni as (
SELECT t_class.classif_code cod_direz, t_class.classif_desc  desc_direz,
			'''' cod_sett, '''' desc_sett, t_class.classif_id
            from siac_r_class_fam_tree r_class_fam_tree,
                siac_t_class			t_class,
                siac_d_class_tipo		d_class_tipo                           
        where                        
             t_class.classif_id 					= 	r_class_fam_tree.classif_id
            and d_class_tipo.classif_tipo_id		=	t_class.classif_tipo_id            
            --DIREZIONE
           AND d_class_tipo.classif_tipo_code=''CDR''
           and t_class.ente_proprietario_id='||ente_proprietario_id_in||'          
             AND t_class.data_cancellazione is NULL
             AND d_class_tipo.data_cancellazione is NULL             
             and r_class_fam_tree.data_cancellazione is NULL                     
            and (t_class.validita_inizio <=now() AND
            	COALESCE(t_class.validita_fine, now()) >=now())    
),            
ele_atti as (           
select r_atto_amm_class.attoamm_id, r_atto_amm_class.classif_id
from siac_r_atto_amm_class 	r_atto_amm_class
where  r_atto_amm_class.ente_proprietario_id='||ente_proprietario_id_in||'       
	and r_atto_amm_class.data_cancellazione is NULL )    
select ele_settori.cod_direz::varchar,
		ele_settori.desc_direz::varchar,
        ele_settori.cod_sett::varchar,
        ele_settori.desc_sett::varchar,
        ele_atti.attoamm_id::integer
from ele_settori
	INNER JOIN   ele_atti on ele_atti.classif_id = ele_settori.classif_id      
UNION
select ele_direzioni.cod_direz::varchar,
		ele_direzioni.desc_direz::varchar,
        ele_direzioni.cod_sett::varchar,
        ele_direzioni.desc_sett::varchar,
        ele_atti.attoamm_id::integer
from ele_direzioni
	INNER JOIN   ele_atti on ele_atti.classif_id = ele_direzioni.classif_id            	
ORDER BY cod_direz, cod_sett';

--raise notice 'sqlQuery = %', sqlQuery;

return query execute sqlQuery;

exception
	when no_data_found THEN
		raise notice 'Struttura SAC Direzione/Settore non esistente' ;
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

-- SIAC-5247 FINE Maurizio

-- SIAC-5317 Inizio
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_capitoloentrata_total (integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_capitoloentrata_total (integer,varchar);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_accertamento_from_capitoloentrata_total (
  _uid_capitoloentrata integer,
  _anno varchar
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	SELECT coalesce(count(*),0) into total
	from
		siac_t_bil_elem a,
		siac_t_bil b2,
		siac_t_periodo c2,
		siac_r_movgest_bil_elem b,
		siac_t_movgest c,
		siac_d_movgest_tipo d,
		siac_t_movgest_ts e,
		siac_t_movgest_ts_det f,
		siac_d_movgest_ts_tipo g,
		siac_d_movgest_ts_det_tipo h,
		siac_r_movgest_ts_stato i,
		siac_d_movgest_stato l,
		siac_r_movgest_class m,
		siac_t_class n,
		siac_d_class_tipo o,
		siac_t_bil p,
		siac_t_periodo q
	where a.bil_id=b2.bil_id
	and c2.periodo_id=b2.periodo_id
	and c.movgest_id=b.movgest_id
	and b.elem_id=a.elem_id
	and d.movgest_tipo_id=c.movgest_tipo_id
	and e.movgest_id=c.movgest_id
	and f.movgest_ts_id=e.movgest_ts_id
	and g.movgest_ts_tipo_id=e.movgest_ts_tipo_id
	and h.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
	and i.movgest_ts_id=e.movgest_ts_id
	and m.movgest_ts_id = e.movgest_ts_id
	and n.classif_id = m.classif_id
	and o.classif_tipo_id = n.classif_tipo_id
	and l.movgest_stato_id=i.movgest_stato_id
	and p.bil_id = c.bil_id
	and q.periodo_id = p.periodo_id
	and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
	and now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now())
	and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
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
	and o.data_cancellazione is null
	and p.data_cancellazione is null
	and q.data_cancellazione is null
	and d.movgest_tipo_code='A'
	and g.movgest_ts_tipo_code='T'
	and h.movgest_ts_det_tipo_code='A'
	and o.classif_tipo_code IN ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
	and a.elem_id=_uid_capitoloentrata
	and q.anno = _anno;
	
	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_capitoloentrata_total (integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_capitoloentrata_total (integer,varchar);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_accertamento_from_capitoloentrata_total (
  _uid_capitoloentrata integer,
  _anno varchar
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	SELECT coalesce(count(*),0) into total
	from
		siac_t_bil_elem a,
		siac_t_bil b2,
		siac_t_periodo c2,
		siac_r_movgest_bil_elem b,
		siac_t_movgest c,
		siac_d_movgest_tipo d,
		siac_t_movgest_ts e,
		siac_t_movgest_ts_det f,
		siac_d_movgest_ts_tipo g,
		siac_d_movgest_ts_det_tipo h,
		siac_r_movgest_ts_stato i,
		siac_d_movgest_stato l,
		siac_r_movgest_class m,
		siac_t_class n,
		siac_d_class_tipo o,
		siac_t_bil p,
		siac_t_periodo q
	where a.bil_id=b2.bil_id
	and c2.periodo_id=b2.periodo_id
	and c.movgest_id=b.movgest_id
	and b.elem_id=a.elem_id
	and d.movgest_tipo_id=c.movgest_tipo_id
	and e.movgest_id=c.movgest_id
	and f.movgest_ts_id=e.movgest_ts_id
	and g.movgest_ts_tipo_id=e.movgest_ts_tipo_id
	and h.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
	and i.movgest_ts_id=e.movgest_ts_id
	and m.movgest_ts_id = e.movgest_ts_id
	and n.classif_id = m.classif_id
	and o.classif_tipo_id = n.classif_tipo_id
	and l.movgest_stato_id=i.movgest_stato_id
	and p.bil_id = c.bil_id
	and q.periodo_id = p.periodo_id
	and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
	and now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now())
	and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
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
	and o.data_cancellazione is null
	and p.data_cancellazione is null
	and q.data_cancellazione is null
	and d.movgest_tipo_code='A'
	and g.movgest_ts_tipo_code='T'
	and h.movgest_ts_det_tipo_code='A'
	and o.classif_tipo_code IN ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
	and a.elem_id=_uid_capitoloentrata
	and q.anno = _anno;
	
	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_soggetto (integer, integer, integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_soggetto (integer, varchar, integer, integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_accertamento_from_soggetto (
  _uid_soggetto integer,
  _anno varchar,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  accertamento_anno integer,
  accertamento_numero numeric,
  accertamento_desc varchar,
  soggetto_code varchar,
  soggetto_desc varchar,
  accertamento_stato_desc varchar,
  importo numeric,
  capitolo_anno varchar,
  capitolo_numero varchar,
  capitolo_articolo varchar,
  ueb_numero varchar,
  attoamm_numero integer,
  attoamm_anno varchar,
  attoamm_tipo_code varchar,
  attoamm_tipo_desc varchar,
  attoamm_stato_desc varchar,
  attoamm_sac_code varchar,
  attoamm_sac_desc varchar,
  pdc_code varchar,
  pdc_desc varchar
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
	rec record;
	v_movgest_ts_id integer;
	v_attoamm_id integer;
BEGIN

	for rec in
		select
			a.elem_id,
			c2.anno,
			a.elem_code,
			a.elem_code2,
			a.elem_code3,
			e.movgest_ts_id,
			c.movgest_anno,
			c.movgest_numero  ,
			c.movgest_desc ,
			f.movgest_ts_det_importo ,
			l.movgest_stato_desc,
			c.movgest_id,
			n.soggetto_code,
			n.soggetto_desc,
			p.classif_code pdc_code,
			p.classif_desc pdc_desc
		from
			siac_t_bil_elem a,
			siac_t_bil b2,
			siac_t_periodo c2,
			siac_r_movgest_bil_elem b,
			siac_t_movgest c,
			siac_d_movgest_tipo d,
			siac_t_movgest_ts e,
			siac_t_movgest_ts_det f,
			siac_d_movgest_ts_tipo g,
			siac_d_movgest_ts_det_tipo h,
			siac_r_movgest_ts_stato i,
			siac_d_movgest_stato l,
			siac_r_movgest_ts_sog m,
			siac_t_soggetto n,
			siac_r_movgest_class o,
			siac_t_class p,
			siac_d_class_tipo q,
			siac_t_bil r,
			siac_t_periodo s
		where a.bil_id=b2.bil_id
		and c2.periodo_id=b2.periodo_id 
		and c.movgest_id=b.movgest_id
		and b.elem_id=a.elem_id
		and d.movgest_tipo_id=c.movgest_tipo_id
		and e.movgest_id=c.movgest_id
		and f.movgest_ts_id=e.movgest_ts_id
		and g.movgest_ts_tipo_id=e.movgest_ts_tipo_id
		and h.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
		and i.movgest_ts_id=e.movgest_ts_id
		and l.movgest_stato_id=i.movgest_stato_id
		and m.movgest_ts_id=e.movgest_ts_id
		and n.soggetto_id=m.soggetto_id
		and o.movgest_ts_id=e.movgest_ts_id
		and p.classif_id=o.classif_id
		and q.classif_tipo_id=p.classif_tipo_id
		and r.bil_id = c.bil_id
		and s.periodo_id = r.periodo_id
		and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
		and now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now())
		and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
		and now() BETWEEN o.validita_inizio and COALESCE(o.validita_fine,now())
		and m.data_cancellazione is null
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
		and o.data_cancellazione is null
		and p.data_cancellazione is null
		and q.data_cancellazione is null
		and r.data_cancellazione is null
		and s.data_cancellazione is null
		and d.movgest_tipo_code='A'
		and g.movgest_ts_tipo_code='T'
		and h.movgest_ts_det_tipo_code='A'
		and q.classif_tipo_code in ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
		and n.soggetto_id=_uid_soggetto
		and s.anno = _anno
		order by
			c.movgest_anno,
			c.movgest_numero
		LIMIT _limit
		OFFSET _offset
		
		loop

			uid:=rec.movgest_id;
			capitolo_anno:=rec.anno;
			capitolo_numero:=rec.elem_code;
			capitolo_articolo:=rec.elem_code2;
			ueb_numero:=rec.elem_code3;
			v_movgest_ts_id:=rec.movgest_ts_id;
			accertamento_anno:=rec.movgest_anno;
			accertamento_numero:=rec.movgest_numero;
			accertamento_desc:=rec.movgest_desc;
			importo:=rec.movgest_ts_det_importo;
			accertamento_stato_desc:=rec.movgest_stato_desc;
			soggetto_code:=rec.soggetto_code;
			soggetto_desc:=rec.soggetto_desc;
			pdc_code:=rec.pdc_code;
			pdc_desc:=rec.pdc_desc;
			
			select
				y.soggetto_code,
				y.soggetto_desc
			into
				soggetto_code,
				soggetto_desc
			from
				siac_r_movgest_ts_sog z,
				siac_t_soggetto y
			where z.soggetto_id=y.soggetto_id
			and now() BETWEEN z.validita_inizio 
			and COALESCE(z.validita_fine,now())
			and now() BETWEEN z.validita_inizio and COALESCE(z.validita_fine,now())
			and z.data_cancellazione is null
			and y.data_cancellazione is null
			and z.movgest_ts_id=v_movgest_ts_id;
			
			--classe di soggetti
			if soggetto_code is null then
			
				select
					l.soggetto_classe_code,
					l.soggetto_classe_desc
				into
					soggetto_code,
					soggetto_desc
				from
					siac_t_soggetto g,
					siac_r_movgest_ts_sogclasse h,
					siac_r_soggetto_classe i,
					siac_d_soggetto_classe l
				where g.soggetto_id=i.soggetto_id
				and h.soggetto_classe_id=l.soggetto_classe_id
				and i.soggetto_classe_id=l.soggetto_classe_id
				and now() between h.validita_inizio and coalesce(h.validita_fine, now())
				and g.data_cancellazione is null
				and h.data_cancellazione is null
				and now() between i.validita_inizio and coalesce(i.validita_fine, now())
				and h.movgest_ts_id=v_movgest_ts_id;
			end if;
			
			select
				q.attoamm_id,
				q.attoamm_numero,
				q.attoamm_anno,
				t.attoamm_stato_desc,
				r.attoamm_tipo_code,
				r.attoamm_tipo_desc
			into
				v_attoamm_id,
				attoamm_numero,
				attoamm_anno,
				attoamm_stato_desc,
				attoamm_tipo_code,
				attoamm_tipo_desc
			from
				siac_r_movgest_ts_atto_amm p,
				siac_t_atto_amm q,
				siac_d_atto_amm_tipo r,
				siac_r_atto_amm_stato s,
				siac_d_atto_amm_stato t
			where p.attoamm_id=q.attoamm_id
			and now() BETWEEN p.validita_inizio and COALESCE(p.validita_fine,now())
			and r.attoamm_tipo_id=q.attoamm_tipo_id
			and s.attoamm_id=q.attoamm_id
			and t.attoamm_stato_id=s.attoamm_stato_id
			and now() BETWEEN s.validita_inizio and COALESCE(s.validita_fine,now())
			and p.movgest_ts_id=rec.movgest_ts_id
			and p.data_cancellazione is null
			and q.data_cancellazione is null
			and r.data_cancellazione is null
			and s.data_cancellazione is null
			and t.data_cancellazione is null;
			
			--sac
			select
				y.classif_code,
				y.classif_desc
			into
				attoamm_sac_code,
				attoamm_sac_desc
			from
				siac_r_atto_amm_class z,
				siac_t_class y,
				siac_d_class_tipo x
			where z.classif_id=y.classif_id
			and x.classif_tipo_id=y.classif_tipo_id
			and x.classif_tipo_code  IN ('CDC', 'CDR')
			and now() BETWEEN z.validita_inizio and COALESCE(z.validita_fine,now())
			and z.data_cancellazione is NULL
			and x.data_cancellazione is NULL
			and y.data_cancellazione is NULL
			and z.attoamm_id=v_attoamm_id;

			return next;
		end loop;

	return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_soggetto_total (integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_accertamento_from_soggetto_total (integer,varchar);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_accertamento_from_soggetto_total (
  _uid_soggetto integer,
  _anno varchar
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	select coalesce(count(*), 0)
	into total
	from
		siac_t_bil_elem a,
		siac_t_bil b2,
		siac_t_periodo c2,
		siac_r_movgest_bil_elem b,
		siac_t_movgest c,
		siac_d_movgest_tipo d,
		siac_t_movgest_ts e,
		siac_t_movgest_ts_det f,
		siac_d_movgest_ts_tipo g,
		siac_d_movgest_ts_det_tipo h,
		siac_r_movgest_ts_stato i,
		siac_d_movgest_stato l,
		siac_r_movgest_ts_sog m,
		siac_t_soggetto n,
		siac_r_movgest_class o,
		siac_t_class p,
		siac_d_class_tipo q,
		siac_t_bil r,
		siac_t_periodo s
	where a.bil_id=b2.bil_id
	and c2.periodo_id=b2.periodo_id 
	and c.movgest_id=b.movgest_id
	and b.elem_id=a.elem_id
	and d.movgest_tipo_id=c.movgest_tipo_id
	and e.movgest_id=c.movgest_id
	and f.movgest_ts_id=e.movgest_ts_id
	and g.movgest_ts_tipo_id=e.movgest_ts_tipo_id
	and h.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
	and i.movgest_ts_id=e.movgest_ts_id
	and l.movgest_stato_id=i.movgest_stato_id
	and m.movgest_ts_id=e.movgest_ts_id
	and n.soggetto_id=m.soggetto_id
	and o.movgest_ts_id=e.movgest_ts_id
	and p.classif_id=o.classif_id
	and q.classif_tipo_id=p.classif_tipo_id
	and r.bil_id = c.bil_id
	and s.periodo_id = r.periodo_id
	and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
	and now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now())
	and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
	and now() BETWEEN o.validita_inizio and COALESCE(o.validita_fine,now())
	and m.data_cancellazione is null
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
	and o.data_cancellazione is null
	and p.data_cancellazione is null
	and q.data_cancellazione is null
	and r.data_cancellazione is null
	and s.data_cancellazione is null
	and d.movgest_tipo_code='A'
	and g.movgest_ts_tipo_code='T'
	and h.movgest_ts_det_tipo_code='A'
	and n.soggetto_id=_uid_soggetto
	and s.anno = _anno;
	
	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

-- SIAC-5152: DROP FUNZIONE CON UNO (vecchia versione) E DUE (nuova versione) PARAMETRI 
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_impegno_from_capitolospesa_total (integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_impegno_from_capitolospesa_total (integer,varchar);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_impegno_from_capitolospesa_total (
  _uid_capitolospesa integer,
  _anno varchar
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	SELECT coalesce(count(*),0) into total
	from
		siac_t_bil_elem a,
		siac_t_bil b2,
		siac_t_periodo c2,
		siac_r_movgest_bil_elem b,
		siac_t_movgest c,
		siac_d_movgest_tipo d,
		siac_t_movgest_ts e,
		siac_t_movgest_ts_det f,
		siac_d_movgest_ts_tipo g,
		siac_d_movgest_ts_det_tipo h,
		siac_r_movgest_ts_stato i,
		siac_d_movgest_stato l,
		siac_r_movgest_class m,
		siac_t_class n,
		siac_d_class_tipo o,
		siac_t_bil p,
		siac_t_periodo q
	where a.bil_id=b2.bil_id
	and c2.periodo_id=b2.periodo_id
	and c.movgest_id=b.movgest_id
	and b.elem_id=a.elem_id
	and d.movgest_tipo_id=c.movgest_tipo_id
	and e.movgest_id=c.movgest_id
	and f.movgest_ts_id=e.movgest_ts_id
	and g.movgest_ts_tipo_id=e.movgest_ts_tipo_id
	and h.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
	and i.movgest_ts_id=e.movgest_ts_id
	and l.movgest_stato_id=i.movgest_stato_id
	and m.movgest_ts_id = e.movgest_ts_id
	and n.classif_id = m.classif_id
	and o.classif_tipo_id = n.classif_tipo_id
	and p.bil_id = c.bil_id
	and q.periodo_id = p.periodo_id
	and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
	and now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now())
	and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
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
	and o.data_cancellazione is null
	and p.data_cancellazione is null
	and q.data_cancellazione is null
	and d.movgest_tipo_code='I'
	and g.movgest_ts_tipo_code='T'
	and h.movgest_ts_det_tipo_code='A'
	and o.classif_tipo_code IN ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
	and a.elem_id=_uid_capitolospesa
	and n.anno = _anno;
	
	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_liquidazione_from_impegno_total (integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_liquidazione_from_impegno_total (integer,varchar);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_liquidazione_from_impegno_total (
  _uid_impegno integer,
  _anno varchar
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	SELECT 
	coalesce(count(*),0) into total
	from (
		select 
			a.liq_id
		from 
			siac_t_liquidazione a,
			siac_r_liquidazione_movgest b,
			siac_t_movgest_ts c,
			siac_t_movgest d,
			siac_r_movgest_bil_elem e,
			siac_t_bil_elem f,
			siac_t_bil g,
			siac_t_periodo h,
			siac_r_liquidazione_soggetto i,
			siac_t_soggetto l,
			siac_r_liquidazione_atto_amm m,
			siac_t_atto_amm n,
			siac_d_atto_amm_tipo o,
			siac_r_atto_amm_stato p,
			siac_d_atto_amm_stato q,
			siac_r_liquidazione_stato r,
			siac_d_liquidazione_stato s
		where a.liq_id=b.liq_id
		and c.movgest_ts_id=b.movgest_ts_id
		and d.movgest_id=c.movgest_id
		and e.movgest_id=d.movgest_id
		and f.elem_id=e.elem_id
		and g.bil_id=f.bil_id
		and h.periodo_id=g.periodo_id
		and i.liq_id=a.liq_id
		and l.soggetto_id=i.soggetto_id
		and m.liq_id=a.liq_id
		and n.attoamm_id=m.attoamm_id
		and o.attoamm_tipo_id=n.attoamm_tipo_id
		and p.attoamm_id=n.attoamm_id
		and p.attoamm_stato_id=q.attoamm_stato_id
		and r.liq_id=a.liq_id
		and r.liq_stato_id=s.liq_stato_id
		and now() BETWEEN b.validita_inizio and coalesce (b.validita_fine,now())
		and now() BETWEEN e.validita_inizio and coalesce (e.validita_fine,now())
		and now() BETWEEN i.validita_inizio and coalesce (i.validita_fine,now())
		and now() BETWEEN m.validita_inizio and coalesce (m.validita_fine,now())
		and now() BETWEEN p.validita_inizio and coalesce (p.validita_fine,now())
		and now() BETWEEN r.validita_inizio and coalesce (r.validita_fine,now())
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
		and o.data_cancellazione is null
		and p.data_cancellazione is null
		and q.data_cancellazione is null
		and r.data_cancellazione is null
		and s.data_cancellazione is null
		and q.attoamm_stato_code<>'ANNULLATO'
		AND d.movgest_id=_uid_impegno
		and h.anno = _anno
	) as liq_id;
	
	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_liquidazione_from_provvedimento_total (integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_liquidazione_from_provvedimento_total (integer,varchar);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_liquidazione_from_provvedimento_total (
  _uid_provvedimento integer,
  _anno varchar
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	SELECT 
	coalesce(count(*),0) into total
	from (
		select
			a.liq_id
		from
			siac_t_liquidazione a,
			siac_r_liquidazione_movgest b,
			siac_t_movgest_ts c,
			siac_t_movgest d,
			siac_r_movgest_bil_elem e,
			siac_t_bil_elem f,
			siac_t_bil g,
			siac_t_periodo h,
			siac_r_liquidazione_soggetto i,
			siac_t_soggetto l,
			siac_r_liquidazione_atto_amm m,
			siac_t_atto_amm n,
			siac_d_atto_amm_tipo o,
			siac_r_atto_amm_stato p,
			siac_d_atto_amm_stato q,
			siac_r_liquidazione_stato r,
			siac_d_liquidazione_stato s
		where a.liq_id=b.liq_id
		and c.movgest_ts_id=b.movgest_ts_id
		and d.movgest_id=c.movgest_id
		and e.movgest_id=d.movgest_id
		and f.elem_id=e.elem_id
		and g.bil_id=f.bil_id
		and h.periodo_id=g.periodo_id
		and i.liq_id=a.liq_id
		and l.soggetto_id=i.soggetto_id
		and m.liq_id=a.liq_id
		and n.attoamm_id=m.attoamm_id
		and o.attoamm_tipo_id=n.attoamm_tipo_id
		and p.attoamm_id=n.attoamm_id
		and p.attoamm_stato_id=q.attoamm_stato_id
		and r.liq_id=a.liq_id
		and r.liq_stato_id=s.liq_stato_id
		and now() BETWEEN b.validita_inizio and coalesce (b.validita_fine,now())
		and now() BETWEEN e.validita_inizio and coalesce (e.validita_fine,now())
		and now() BETWEEN i.validita_inizio and coalesce (i.validita_fine,now())
		and now() BETWEEN m.validita_inizio and coalesce (m.validita_fine,now())
		and now() BETWEEN p.validita_inizio and coalesce (p.validita_fine,now())
		and now() BETWEEN r.validita_inizio and coalesce (r.validita_fine,now())
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
		and o.data_cancellazione is null
		and p.data_cancellazione is null
		and q.data_cancellazione is null
		and r.data_cancellazione is null
		and s.data_cancellazione is null
		and q.attoamm_stato_code<>'ANNULLATO'
		AND n.attoamm_id=_uid_provvedimento
		AND h.anno = _anno
	) as liq_id;
	
	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_mandato_from_capitolospesa_total (
  _uid_capitolospesa integer
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	SELECT coalesce(count(*),0) 
	into total
	from (
		SELECT 1
		from
			siac_r_ordinativo_bil_elem r,
			siac_t_bil_elem s,
			siac_t_ordinativo y,
			siac_d_ordinativo_tipo i
		where s.elem_id=r.elem_id
		and y.ord_id=r.ord_id
		and s.elem_id=_uid_capitolospesa
		and i.ord_tipo_id=y.ord_tipo_id
		and i.ord_tipo_code='P'
		and r.data_cancellazione is null
		and s.data_cancellazione is null
		and i.data_cancellazione is null
		and now() BETWEEN r.validita_inizio and coalesce (r.validita_fine,now())
		and y.data_cancellazione is null
	)
  as ord_id ;
	
	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

-- SIAC-5317 FINE

-- SIAC-5326 INIZIO

DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_impegno_from_capitolospesa_total (integer);
DROP FUNCTION IF EXISTS siac.fnc_siac_cons_entita_impegno_from_capitolospesa_total (integer,varchar);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_impegno_from_capitolospesa_total (
  _uid_capitolospesa integer,
  _anno varchar
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	SELECT coalesce(count(*),0) into total
	from
		siac_t_bil_elem a,
		siac_t_bil b2,
		siac_t_periodo c2,
		siac_r_movgest_bil_elem b,
		siac_t_movgest c,
		siac_d_movgest_tipo d,
		siac_t_movgest_ts e,
		siac_t_movgest_ts_det f,
		siac_d_movgest_ts_tipo g,
		siac_d_movgest_ts_det_tipo h,
		siac_r_movgest_ts_stato i,
		siac_d_movgest_stato l,
		siac_r_movgest_class m,
		siac_t_class n,
		siac_d_class_tipo o,
		siac_t_bil p,
		siac_t_periodo q
	where a.bil_id=b2.bil_id
	and c2.periodo_id=b2.periodo_id
	and c.movgest_id=b.movgest_id
	and b.elem_id=a.elem_id
	and d.movgest_tipo_id=c.movgest_tipo_id
	and e.movgest_id=c.movgest_id
	and f.movgest_ts_id=e.movgest_ts_id
	and g.movgest_ts_tipo_id=e.movgest_ts_tipo_id
	and h.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
	and i.movgest_ts_id=e.movgest_ts_id
	and l.movgest_stato_id=i.movgest_stato_id
	and m.movgest_ts_id = e.movgest_ts_id
	and n.classif_id = m.classif_id
	and o.classif_tipo_id = n.classif_tipo_id
	and p.bil_id = c.bil_id
	and q.periodo_id = p.periodo_id
	and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
	and now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now())
	and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
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
	and o.data_cancellazione is null
	and p.data_cancellazione is null
	and q.data_cancellazione is null
	and d.movgest_tipo_code='I'
	and g.movgest_ts_tipo_code='T'
	and h.movgest_ts_det_tipo_code='A'
	and o.classif_tipo_code IN ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
	and a.elem_id=_uid_capitolospesa
	and q.anno = _anno;
	
	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

-- SIAC-5326 FINE

-- SIAC-5245 INIZIO
CREATE OR REPLACE FUNCTION siac.fnc_siac_clearo_impegnato_quietanzato (
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_anno_provv varchar,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE

  anno_bilancio_int integer;

BEGIN

IF p_data IS NULL THEN
   IF p_anno_bilancio::integer < to_char(now(),'YYYY')::integer THEN
      p_data = to_timestamp('31/12/'||p_anno_bilancio, 'dd/mm/yyyy');
   ELSE
      p_data := now();
   END IF;   
END IF;

DELETE FROM  siac_clearo_impegnato_quietanzato 
WHERE ente_proprietario_id = p_ente_proprietario_id 
AND   anno_bilancio = p_anno_bilancio;

/*DELETE FROM  siac_clearo_impegnato
WHERE ente_proprietario_id = p_ente_proprietario_id 
AND   anno_bilancio = p_anno_bilancio;

DELETE FROM  siac_clearo_quietanzato 
WHERE ente_proprietario_id = p_ente_proprietario_id 
AND   anno_bilancio = p_anno_bilancio;*/

anno_bilancio_int := p_anno_bilancio::integer;

-- Dati estratti per l'impegnato
WITH provvedimenti AS (
SELECT 
a.movgest_ts_id,
b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
(case when cl.classif_code is not null and cl.classif_code!='' then e.attoamm_tipo_code||' '||cl.classif_code ELSE
         e.attoamm_tipo_code end ) attoamm_tipo_code, 
e.attoamm_tipo_desc, d.attoamm_stato_desc
FROM 
siac.siac_r_movgest_ts_atto_amm a, 
siac.siac_r_atto_amm_stato c, 
siac.siac_d_atto_amm_stato d, siac.siac_d_atto_amm_tipo e,
siac.siac_t_atto_amm b
left join siac_r_atto_amm_class rc 
                  join siac_t_class cl join siac_d_class_tipo tipoc on ( tipoc.classif_tipo_id=cl.classif_tipo_id
                                                                   and  tipoc.classif_tipo_code in ('CDC','CDR'))
                    on (rc.classif_id=cl.classif_id
                   and cl.data_cancellazione is null )
     on (b.attoamm_id=rc.attoamm_id                                   
     and rc.data_cancellazione is null
     and rc.validita_fine is null )
WHERE a.ente_proprietario_id=p_ente_proprietario_id
--AND b.attoamm_anno >= p_anno_bilancio
AND b.attoamm_anno >= p_anno_provv
AND a.attoamm_id=b.attoamm_id
AND c.attoamm_id = b.attoamm_id 
AND d.attoamm_stato_id = c.attoamm_stato_id
AND e.attoamm_tipo_id = b.attoamm_tipo_id
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   d.data_cancellazione IS NULL
AND   e.data_cancellazione IS NULL
-- AND   p_data BETWEEN a.validita_inizio and COALESCE(a.validita_fine,p_data)
-- AND   p_data BETWEEN c.validita_inizio and COALESCE(c.validita_fine,p_data)
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
AND   d.validita_fine IS NULL
AND   e.validita_fine IS NULL
)
, impegnato AS (
SELECT
t_movgest_ts.movgest_ts_id,
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
siac_d_movgest_stato d_movgest_stato 
WHERE t_movgest.movgest_id=t_movgest_ts.movgest_id    
AND t_bil.bil_id= t_movgest.bil_id   
AND t_periodo.periodo_id=t_bil.periodo_id    
AND d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id 
AND r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id     
AND r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id   	       
AND t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
AND d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
AND t_movgest.ente_proprietario_id=p_ente_proprietario_id
AND t_periodo.anno = p_anno_bilancio
-- AND t_movgest.movgest_anno = anno_bilancio_int
AND t_movgest.movgest_anno <= anno_bilancio_int
AND t_movgest.parere_finanziario = 'TRUE'
AND d_movgest_tipo.movgest_tipo_code='I'
AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A' -- importo attuale 
AND d_movgest_stato.movgest_stato_code = 'D' 
--AND d_movgest_ts_tipo.movgest_ts_tipo_code = 'T' --solo impegni non sub-impegni
AND t_movgest_ts.data_cancellazione IS NULL
AND t_movgest.data_cancellazione IS NULL   
AND t_bil.data_cancellazione IS NULL 
AND t_periodo.data_cancellazione IS NULL
AND d_movgest_tipo.data_cancellazione IS NULL            
AND t_movgest_ts_det.data_cancellazione IS NULL
AND d_movgest_ts_det_tipo.data_cancellazione IS NULL
AND d_movgest_ts_tipo.data_cancellazione IS NULL
AND r_movgest_ts_stato.data_cancellazione IS NULL
AND d_movgest_stato.data_cancellazione IS NULL
-- AND p_data BETWEEN r_movgest_ts_stato.validita_inizio and COALESCE(r_movgest_ts_stato.validita_fine,p_data)
and  t_movgest.validita_fine is null
and  t_bil.validita_fine is null
and  t_periodo.validita_fine is null
and  t_movgest_ts.validita_fine is null
and  d_movgest_tipo.validita_fine is null
and  t_movgest_ts_det.validita_fine is null
and  d_movgest_ts_det_tipo.validita_fine is null
and  d_movgest_ts_tipo.validita_fine is null
and  r_movgest_ts_stato.validita_fine is null
and  d_movgest_stato.validita_fine is null
)
/*, t_flagDaRiaccertamento as (
SELECT 
a.movgest_ts_id,
a."boolean" flagDaRiaccertamento
FROM  siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE b.attr_code='flagDaRiaccertamento' 
AND a.ente_proprietario_id = p_ente_proprietario_id 
AND a.attr_id = b.attr_id
AND a."boolean"  = 'N'
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
AND p_data BETWEEN a.validita_inizio and COALESCE(a.validita_fine,p_data)
)*/
, sogg as (SELECT 
a.movgest_ts_id,
b.soggetto_code, b.soggetto_desc, b.codice_fiscale, 
b.codice_fiscale_estero, b.partita_iva
FROM siac_r_movgest_ts_sog a, siac_t_soggetto b
WHERE a.soggetto_id = b.soggetto_id
AND a.ente_proprietario_id = p_ente_proprietario_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
-- AND p_data BETWEEN a.validita_inizio and COALESCE(a.validita_fine,p_data)
AND a.validita_fine is null
AND b.validita_fine is null
)
, sogcla as (SELECT 
a.movgest_ts_id,
b.soggetto_classe_code, b.soggetto_classe_desc
FROM siac_r_movgest_ts_sogclasse a, siac.siac_d_soggetto_classe b
WHERE a.ente_proprietario_id = p_ente_proprietario_id 
AND a.soggetto_classe_id = b.soggetto_classe_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
-- AND p_data BETWEEN a.validita_inizio and COALESCE(a.validita_fine,p_data)
AND a.validita_fine is null
AND b.validita_fine is null
)
--INSERT INTO siac_clearo_impegnato
INSERT INTO siac_clearo_impegnato_quietanzato
(ente_proprietario_id,
 anno_bilancio,
 anno_atto_amministrativo,
 num_atto_amministrativo,
 oggetto_atto_amministrativo,
 note_atto_amministrativo,
 cod_tipo_atto_amministrativo,
 desc_tipo_atto_amministrativo,
 desc_stato_atto_amministrativo,
 anno_impegno,
 num_impegno,
 impegnato,
 cod_soggetto,
 desc_soggetto,
 cf_soggetto,
 cf_estero_soggetto,
 p_iva_soggetto,
 cod_classe_soggetto,
 desc_classe_soggetto,
 tipo_impegno,
 tipo_importo)   
SELECT 
p_ente_proprietario_id,
p_anno_bilancio,
provvedimenti.attoamm_anno, provvedimenti.attoamm_numero, provvedimenti.attoamm_oggetto, provvedimenti.attoamm_note,
provvedimenti.attoamm_tipo_code, provvedimenti.attoamm_tipo_desc, provvedimenti.attoamm_stato_desc,
impegnato.movgest_anno, impegnato.movgest_numero, 
--impegnato.movgest_ts_det_importo, 
COALESCE(SUM(impegnato.movgest_ts_det_importo),0) importo_impegnato,
sogg.soggetto_code, sogg.soggetto_desc, sogg.codice_fiscale, sogg.codice_fiscale_estero, sogg.partita_iva,
sogcla.soggetto_classe_code, sogcla.soggetto_classe_desc,
impegnato.movgest_ts_tipo_code,
'I'
FROM provvedimenti
INNER JOIN impegnato ON impegnato.movgest_ts_id = provvedimenti.movgest_ts_id
-- INNER JOIN t_flagDaRiaccertamento ON t_flagDaRiaccertamento.movgest_ts_id = impegnato.movgest_ts_id
LEFT JOIN sogg ON sogg.movgest_ts_id = impegnato.movgest_ts_id
LEFT JOIN sogcla ON sogcla.movgest_ts_id = impegnato.movgest_ts_id
GROUP BY
p_ente_proprietario_id,
p_anno_bilancio,
provvedimenti.attoamm_anno,
provvedimenti.attoamm_numero, 
provvedimenti.attoamm_oggetto, 
provvedimenti.attoamm_note,
provvedimenti.attoamm_tipo_code, 
provvedimenti.attoamm_tipo_desc, 
provvedimenti.attoamm_stato_desc,
impegnato.movgest_anno, 
impegnato.movgest_numero,
sogg.soggetto_code, 
sogg.soggetto_desc, 
sogg.codice_fiscale, 
sogg.codice_fiscale_estero, 
sogg.partita_iva,
sogcla.soggetto_classe_code, 
sogcla.soggetto_classe_desc,
impegnato.movgest_ts_tipo_code,
'I'::varchar;

-- Dati estratti per il quietanzato
WITH provvedimenti AS (
SELECT 
a.movgest_ts_id,
b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
(case when cl.classif_code is not null and cl.classif_code!='' then e.attoamm_tipo_code||' '||cl.classif_code ELSE
         e.attoamm_tipo_code end ) attoamm_tipo_code, 
e.attoamm_tipo_desc, d.attoamm_stato_desc,
t_movgest.movgest_anno,
t_movgest.movgest_numero
FROM 
siac.siac_r_movgest_ts_atto_amm a,
siac.siac_t_movgest_ts t_movgest_ts,
siac.siac_t_movgest t_movgest,
siac.siac_r_atto_amm_stato c, 
siac.siac_d_atto_amm_stato d, siac.siac_d_atto_amm_tipo e,
siac.siac_t_atto_amm b 
left join siac_r_atto_amm_class rc 
                  join siac_t_class cl join siac_d_class_tipo tipoc on ( tipoc.classif_tipo_id=cl.classif_tipo_id
                                                                   and  tipoc.classif_tipo_code in ('CDC','CDR'))
                    on (rc.classif_id=cl.classif_id
                   and cl.data_cancellazione is null )
     on (b.attoamm_id=rc.attoamm_id                                   
     and rc.data_cancellazione is null
     and rc.validita_fine is null )
WHERE a.ente_proprietario_id=p_ente_proprietario_id
--AND b.attoamm_anno >= p_anno_bilancio
AND b.attoamm_anno >= p_anno_provv
AND a.attoamm_id=b.attoamm_id
AND t_movgest_ts.movgest_ts_id = a.movgest_ts_id
AND t_movgest.movgest_id = t_movgest_ts.movgest_id
AND c.attoamm_id = b.attoamm_id 
AND d.attoamm_stato_id = c.attoamm_stato_id
AND e.attoamm_tipo_id = b.attoamm_tipo_id
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   d.data_cancellazione IS NULL
AND   e.data_cancellazione IS NULL
AND   t_movgest_ts.data_cancellazione IS NULL
AND   t_movgest.data_cancellazione IS NULL
-- AND   p_data BETWEEN a.validita_inizio and COALESCE(a.validita_fine,p_data)
-- AND   p_data BETWEEN c.validita_inizio and COALESCE(c.validita_fine,p_data)
AND a.validita_fine is null
AND b.validita_fine is null
AND c.validita_fine is null
AND d.validita_fine is null
AND e.validita_fine is null
AND t_movgest_ts.validita_fine IS NULL
AND t_movgest.validita_fine IS NULL
),
impegnato AS (
SELECT
t_movgest_ts.movgest_ts_id,
t_movgest.movgest_anno, 
t_movgest.movgest_numero,
t_movgest_ts.movgest_ts_code,
d_movgest_ts_tipo.movgest_ts_tipo_code
FROM siac_t_movgest t_movgest,
siac_t_bil t_bil,
siac_t_periodo t_periodo,
siac_t_movgest_ts t_movgest_ts,    
siac_d_movgest_tipo d_movgest_tipo,            
siac_d_movgest_ts_tipo d_movgest_ts_tipo,
siac_r_movgest_ts_stato r_movgest_ts_stato,
siac_d_movgest_stato d_movgest_stato 
WHERE t_movgest.movgest_id=t_movgest_ts.movgest_id    
AND t_bil.bil_id= t_movgest.bil_id   
AND t_periodo.periodo_id=t_bil.periodo_id    
AND d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id 
AND r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id     
AND r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id   	       
AND d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
AND t_movgest.ente_proprietario_id=p_ente_proprietario_id
AND t_periodo.anno = p_anno_bilancio
--AND t_movgest.movgest_anno = 2017
AND t_movgest.parere_finanziario = 'TRUE' -- Da considrare?  24.08.2017 Sofia secondo me deve rimanere
AND d_movgest_tipo.movgest_tipo_code='I'
AND d_movgest_stato.movgest_stato_code = 'D' -- Da considrare? 24.08.2017 Sofia secondo me deve rimanere
--AND d_movgest_ts_tipo.movgest_ts_tipo_code = 'T' -- solo impegni non sub-impegni
AND t_movgest_ts.data_cancellazione IS NULL
AND t_movgest.data_cancellazione IS NULL   
AND t_bil.data_cancellazione IS NULL 
AND t_periodo.data_cancellazione IS NULL
AND d_movgest_tipo.data_cancellazione IS NULL            
AND d_movgest_ts_tipo.data_cancellazione IS NULL
AND r_movgest_ts_stato.data_cancellazione IS NULL
AND d_movgest_stato.data_cancellazione IS NULL
-- AND p_data BETWEEN r_movgest_ts_stato.validita_inizio and COALESCE(r_movgest_ts_stato.validita_fine,p_data)
and  t_movgest.validita_fine is null
and  t_bil.validita_fine is null
and  t_periodo.validita_fine is null
and  t_movgest_ts.validita_fine is null
and  d_movgest_tipo.validita_fine is null
and  d_movgest_ts_tipo.validita_fine is null
and  r_movgest_ts_stato.validita_fine is null
and  d_movgest_stato.validita_fine is null
)
, sogg as (SELECT
a.movgest_ts_id,
b.soggetto_code, b.soggetto_desc, b.codice_fiscale, 
b.codice_fiscale_estero, b.partita_iva
FROM siac_r_movgest_ts_sog a, siac_t_soggetto b
WHERE a.soggetto_id = b.soggetto_id
AND a.ente_proprietario_id = p_ente_proprietario_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
-- AND p_data BETWEEN a.validita_inizio and COALESCE(a.validita_fine,p_data)
AND  a.validita_fine is null
AND  b.validita_fine is null

)
, sogcla as (SELECT 
a.movgest_ts_id,
b.soggetto_classe_code, b.soggetto_classe_desc
FROM siac_r_movgest_ts_sogclasse a, siac.siac_d_soggetto_classe b
WHERE a.ente_proprietario_id = p_ente_proprietario_id 
AND a.soggetto_classe_id = b.soggetto_classe_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
-- AND p_data BETWEEN a.validita_inizio and COALESCE(a.validita_fine,p_data)
AND  a.validita_fine is null
AND  b.validita_fine is null
)
, impliquidatoquietanzato AS (
WITH quietanzato AS (
  SELECT e.ord_ts_det_importo, a.ord_id, b.ord_ts_id
  FROM 
  siac_t_ordinativo a,
  siac_t_ordinativo_ts b,
  siac_r_ordinativo_stato c, siac_d_ordinativo_stato d,
  siac_t_ordinativo_ts_det e, siac_d_ordinativo_ts_det_tipo f
  WHERE a.ente_proprietario_id = p_ente_proprietario_id 
  AND  a.ord_id = b.ord_id
  AND  c.ord_id = b.ord_id
  AND  c.ord_stato_id = d.ord_stato_id
  AND  e.ord_ts_id = b.ord_ts_id
  AND  f.ord_ts_det_tipo_id = e.ord_ts_det_tipo_id
  AND  d.ord_stato_code= 'Q'
  AND  f.ord_ts_det_tipo_code = 'A'  
  AND  a.data_cancellazione IS NULL
  AND  b.data_cancellazione IS NULL
  AND  c.data_cancellazione IS NULL 
  AND  d.data_cancellazione IS NULL  
  AND  e.data_cancellazione IS NULL
  AND  f.data_cancellazione IS NULL
  -- AND   p_data BETWEEN c.validita_inizio and COALESCE(c.validita_fine,p_data)
  AND  a.validita_fine is null
  AND  b.validita_fine is null
  AND  c.validita_fine is null
  AND  d.validita_fine is null
  AND  e.validita_fine is null
  AND  f.validita_fine is null            
/*  )
, sogg AS (SELECT 
a.ord_id,
b.soggetto_code, b.soggetto_desc, b.codice_fiscale, 
b.codice_fiscale_estero, b.partita_iva
FROM siac_r_ordinativo_soggetto a, siac_t_soggetto b
WHERE a.soggetto_id = b.soggetto_id
AND a.ente_proprietario_id = p_ente_proprietario_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
AND p_data BETWEEN a.validita_inizio and COALESCE(a.validita_fine,p_data)*/
)
SELECT
quietanzato.ord_ts_det_importo,/*
sogg.soggetto_code, sogg.soggetto_desc, sogg.codice_fiscale, 
sogg.codice_fiscale_estero, sogg.partita_iva,*/
b.movgest_ts_id,
d.movgest_anno,
d.movgest_numero
FROM  quietanzato
--INNER JOIN sogg ON quietanzato.ord_id = sogg.ord_id
INNER JOIN siac_r_liquidazione_ord a ON  a.sord_id = quietanzato.ord_ts_id
INNER JOIN siac_r_liquidazione_movgest b ON b.liq_id = a.liq_id
INNER JOIN siac_t_movgest_ts c ON b.movgest_ts_id = c.movgest_ts_id
INNER JOIN siac_t_movgest d ON d.movgest_id = c.movgest_id
WHERE a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   d.data_cancellazione IS NULL
-- AND   p_data BETWEEN a.validita_inizio and COALESCE(a.validita_fine,p_data)
-- AND   p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine,p_data)
AND  a.validita_fine is null
AND  b.validita_fine is null
AND  c.validita_fine is null
AND  d.validita_fine is null
)
--INSERT INTO siac_clearo_quietanzato
INSERT INTO siac_clearo_impegnato_quietanzato
(ente_proprietario_id,
 anno_bilancio,
 anno_atto_amministrativo,
 num_atto_amministrativo,
 oggetto_atto_amministrativo,
 note_atto_amministrativo,
 cod_tipo_atto_amministrativo,
 desc_tipo_atto_amministrativo,
 desc_stato_atto_amministrativo,
 anno_impegno,
 num_impegno,
 quietanzato,
 cod_soggetto,
 desc_soggetto,
 cf_soggetto,
 cf_estero_soggetto,
 p_iva_soggetto,
 cod_classe_soggetto,
 desc_classe_soggetto, 
 tipo_impegno,
 tipo_importo)
SELECT 
p_ente_proprietario_id,
p_anno_bilancio,
provvedimenti.attoamm_anno, provvedimenti.attoamm_numero, provvedimenti.attoamm_oggetto, provvedimenti.attoamm_note,
provvedimenti.attoamm_tipo_code, provvedimenti.attoamm_tipo_desc, provvedimenti.attoamm_stato_desc,
impegnato.movgest_anno, impegnato.movgest_numero,
-- impliquidatoquietanzato.ord_ts_det_importo,
COALESCE(SUM(impliquidatoquietanzato.ord_ts_det_importo),0) importo_quietanzato, 
sogg.soggetto_code, sogg.soggetto_desc, sogg.codice_fiscale, sogg.codice_fiscale_estero, sogg.partita_iva,
sogcla.soggetto_classe_code, sogcla.soggetto_classe_desc, 
-- impliquidatoquietanzato.soggetto_code, impliquidatoquietanzato.soggetto_desc, impliquidatoquietanzato.codice_fiscale, 
-- impliquidatoquietanzato.codice_fiscale_estero, impliquidatoquietanzato.partita_iva,
impegnato.movgest_ts_tipo_code,
'Q'
FROM provvedimenti
INNER JOIN impegnato ON impegnato.movgest_ts_id = provvedimenti.movgest_ts_id
LEFT  JOIN sogg ON sogg.movgest_ts_id = impegnato.movgest_ts_id
LEFT  JOIN sogcla ON sogcla.movgest_ts_id = impegnato.movgest_ts_id
--INNER JOIN impliquidatoquietanzato ON impliquidatoquietanzato.movgest_ts_id = provvedimenti.movgest_ts_id
INNER JOIN impliquidatoquietanzato ON impliquidatoquietanzato.movgest_anno = provvedimenti.movgest_anno
                                   AND impliquidatoquietanzato.movgest_numero = provvedimenti.movgest_numero
GROUP BY
p_ente_proprietario_id,
p_anno_bilancio,
provvedimenti.attoamm_anno, 
provvedimenti.attoamm_numero, 
provvedimenti.attoamm_oggetto, 
provvedimenti.attoamm_note,
provvedimenti.attoamm_tipo_code, 
provvedimenti.attoamm_tipo_desc, 
provvedimenti.attoamm_stato_desc,
impegnato.movgest_anno, 
impegnato.movgest_numero,
/*impliquidatoquietanzato.soggetto_code, 
impliquidatoquietanzato.soggetto_desc, 
impliquidatoquietanzato.codice_fiscale, 
impliquidatoquietanzato.codice_fiscale_estero, 
impliquidatoquietanzato.partita_iva,*/
sogg.soggetto_code, 
sogg.soggetto_desc, 
sogg.codice_fiscale, 
sogg.codice_fiscale_estero, 
sogg.partita_iva,
sogcla.soggetto_classe_code, 
sogcla.soggetto_classe_desc,
impegnato.movgest_ts_tipo_code,
'Q'::varchar;

esito:='ok';

EXCEPTION
WHEN others THEN
  esito:='Funzione carico impegnato quietanzato (FNC_SIAC_CLEARO_IMPEGNATO_QUIETANZATO) terminata con errori';
  RAISE EXCEPTION '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;
-- SIAC-5245 FINE

-- SIAC-5249 INIZIO

/* ---------------------------------------------------------------------- */
/* Add table "siac.siac_r_ruolo_op_bil"                                   */
/* ---------------------------------------------------------------------- */

CREATE TABLE siac.siac_r_ruolo_op_bil (
    ruolo_op_bil_id SERIAL  NOT NULL,
    ruolo_op_id INTEGER  NOT NULL,
    bil_id INTEGER  NOT NULL,
    validita_inizio TIMESTAMP  NOT NULL,
    validita_fine TIMESTAMP,
    ente_proprietario_id INTEGER  NOT NULL,
    data_creazione TIMESTAMP DEFAULT now()  NOT NULL,
    data_modifica TIMESTAMP DEFAULT now()  NOT NULL,
    data_cancellazione TIMESTAMP,
    login_operazione CHARACTER VARYING(200)  NOT NULL,
    CONSTRAINT PK_siac_r_ruolo_op_bil PRIMARY KEY (ruolo_op_bil_id)
);

CREATE UNIQUE INDEX IDX_siac_r_ruolo_op_bil_1 ON siac.siac_r_ruolo_op_bil (ruolo_op_id,bil_id,validita_inizio,ente_proprietario_id) where data_cancellazione IS NULL;

/* ---------------------------------------------------------------------- */
/* Add foreign key constraints                                            */
/* ---------------------------------------------------------------------- */

ALTER TABLE siac.siac_r_ruolo_op_bil ADD CONSTRAINT siac_d_ruolo_op_siac_r_ruolo_op_bil 
    FOREIGN KEY (ruolo_op_id) REFERENCES siac.siac_d_ruolo_op (ruolo_op_id);

ALTER TABLE siac.siac_r_ruolo_op_bil ADD CONSTRAINT siac_t_bil_siac_r_ruolo_op_bil 
    FOREIGN KEY (bil_id) REFERENCES siac.siac_t_bil (bil_id);

	
-- SIAC-5249 FINE


-- Allineamento function INIZIO
CREATE OR REPLACE FUNCTION siac.fnc_siac_atto_amm_aggiorna_stato_movgest (
  attoamm_id_in integer,
  attoamm_stato_code_in varchar,
  is_esecutivo_in boolean,
  login_operazione_in varchar
)
RETURNS TABLE (
  _regmovfin_id integer
) AS
$body$
DECLARE

stato_new_id integer;
stato_new_id_no_sog integer;
login_oper varchar;
valid_fine timestamp;
valid_inizio timestamp;
data_oper timestamp;
ente_proprietario_new_id integer;
esito varchar;
cur_upd_sogg record;
cur_upd_nosogg record;
cur_regmovfin record;
cur_regmovfin_gsa record;
cur_regmovfin_gsa_acc record;
cur_regmovfin_acc record;
elem_id_exists integer;
ambito_id_gsa integer;
macroaggegato_exists varchar;
evento_code_reg_movfin varchar;
cur_mod_movgest_imp record;
cur_mod_movgest_acc record;
cur_mod_movgest_imp_gsa record;
cur_mod_movgest_acc_gsa record;
cur_mod_movgest_imp_gsa_sog record;
cur_mod_movgest_acc_gsa_sog record;
mod_stato_code_in varchar;
query text;
begin
mod_stato_code_in:='V';
elem_id_exists:=0;
macroaggegato_exists:=null;
evento_code_reg_movfin:=null;
ambito_id_gsa:=null;
data_oper:=now();
valid_fine:=now();
valid_inizio:=now()+ interval '1 second';
login_oper:= login_operazione_in||' - '||'fnc_siac_atto_amm_aggiorna_stato_movgest';

select movgest_stato_id,ente_proprietario_id into stato_new_id,ente_proprietario_new_id
     from siac_d_movgest_stato where
    ente_proprietario_id=(select ente_proprietario_id from siac_t_atto_amm where attoamm_id=attoamm_id_in)
    and movgest_stato_code='D';
       	
  


if is_esecutivo_in = true then
 
    update siac_t_movgest set parere_finanziario=true, parere_finanziario_data_modifica=valid_inizio, parere_finanziario_login_operazione=login_operazione_in
    where  movgest_id in ( 
    select distinct mg.movgest_id
    from siac_t_atto_amm aa,
    siac_r_movgest_ts_atto_amm mga,
    siac_t_movgest_ts ts, siac_t_movgest mg, siac_r_movgest_ts_stato tss, siac_d_movgest_stato mgs,
    siac_t_bil b, siac_d_fase_operativa fo, siac_r_bil_fase_operativa bfo, siac_d_movgest_tipo mt, siac_d_movgest_ts_tipo tt
    where mga.attoamm_id=aa.attoamm_id
    and ts.movgest_ts_id=mga.movgest_ts_id
    and mg.movgest_id=ts.movgest_id
    and tss.movgest_ts_id=ts.movgest_ts_id
    and mgs.movgest_stato_id=tss.movgest_stato_id
    and mgs.movgest_stato_code<>'A'
    and b.bil_id=mg.bil_id
    and bfo.fase_operativa_id=fo.fase_operativa_id
    and bfo.bil_id=b.bil_id
    and aa.attoamm_id=attoamm_id_in
    and mt.movgest_tipo_id=mg.movgest_tipo_id
    and tt.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and now() between tss.validita_inizio and COALESCE(tss.validita_fine,now())
    and aa.data_cancellazione is null
    and mga.data_cancellazione is null
    and ts.data_cancellazione is null
    and mg.data_cancellazione is null
    and tss.data_cancellazione is null
    and mgs.data_cancellazione is null
    and b.data_cancellazione is null
    and fo.data_cancellazione is null
    and bfo.data_cancellazione is null
    and mt.data_cancellazione is null
    and tt.data_cancellazione is null
    );
  
  --parerefinanziario = true dei momovimenti collegati 
end if;  


if attoamm_stato_code_in='DEFINITIVO' then
   /* select movgest_stato_id,ente_proprietario_id into stato_new_id,ente_proprietario_new_id
     from siac_d_movgest_stato where
    ente_proprietario_id=(select ente_proprietario_id from siac_t_atto_amm where attoamm_id=attoamm_id_in)
    and movgest_stato_code='D';*/
    
    select movgest_stato_id,ente_proprietario_id into stato_new_id_no_sog,ente_proprietario_new_id
     from siac_d_movgest_stato where
    ente_proprietario_id=(select ente_proprietario_id from siac_t_atto_amm where attoamm_id=attoamm_id_in)
    and movgest_stato_code='N';
--aggiorna a DEFINITIVO se c'è un soggetto associato all movgest_ts
--aggiorna a DEFINITIVO NON LIQUIDABILE se non c'è un soggetto associato all movgest_ts

--esiste soggetto?

--------------------------SOGGETTO ASSOCIATO aggiorno a DEFINITIVO INIZIO-----------------------------------

--si 
for cur_upd_sogg in
select tss.movgest_stato_r_id, ts.movgest_ts_id, b.bil_id, mg.movgest_id,
mt.movgest_tipo_code, tt.movgest_ts_tipo_code
from siac_t_atto_amm aa,
siac_r_movgest_ts_atto_amm mga,
siac_t_movgest_ts ts, siac_t_movgest mg, siac_r_movgest_ts_stato tss, 
siac_d_movgest_stato mgs,
siac_t_bil b, siac_d_fase_operativa fo, siac_r_bil_fase_operativa bfo, 
siac_d_movgest_tipo mt, siac_d_movgest_ts_tipo tt
where mga.attoamm_id=aa.attoamm_id
and ts.movgest_ts_id=mga.movgest_ts_id
and mg.movgest_id=ts.movgest_id
and tss.movgest_ts_id=ts.movgest_ts_id
and mgs.movgest_stato_id=tss.movgest_stato_id
and mgs.movgest_stato_code<>'A'
and b.bil_id=mg.bil_id
and bfo.fase_operativa_id=fo.fase_operativa_id
and bfo.bil_id=b.bil_id
and fo.fase_operativa_code<>'C'
and aa.attoamm_id=attoamm_id_in
and mt.movgest_tipo_id=mg.movgest_tipo_id
and tt.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
and mgs.movgest_stato_code='P'
and now() between tss.validita_inizio and COALESCE(tss.validita_fine,now())
and aa.data_cancellazione is null
and mga.data_cancellazione is null
and ts.data_cancellazione is null
and mg.data_cancellazione is null
and tss.data_cancellazione is null
and mgs.data_cancellazione is null
and b.data_cancellazione is null
and fo.data_cancellazione is null
and bfo.data_cancellazione is null
and mt.data_cancellazione is null
and tt.data_cancellazione is null
and ( 
 (    exists (
               select 1
               from siac_r_movgest_ts_sog sog
               where sog.movgest_ts_id = ts.movgest_ts_id
      		 )
  ) or 
  (    
      exists (
               select 1
               from siac_r_movgest_ts_sogclasse sogcl
               where  sogcl.movgest_ts_id = ts.movgest_ts_id
      )
  ))    
loop

    update siac_r_movgest_ts_stato set validita_fine=valid_fine, data_modifica=valid_fine, 
    data_cancellazione=valid_fine,login_operazione=login_operazione||' - '||'fnc_siac_atto_amm_aggiorna_stato_movgest'
    where movgest_stato_r_id=cur_upd_sogg.movgest_stato_r_id;

    INSERT INTO siac_r_movgest_ts_stato (movgest_ts_id,movgest_stato_id,validita_inizio,ente_proprietario_id,data_creazione,login_operazione)
    VALUES (cur_upd_sogg.movgest_ts_id,stato_new_id,valid_inizio,ente_proprietario_new_id,valid_inizio,login_oper);
    
----------------REGISTRAZIONE IMPEGNO INIZIO (si fa solo se c'è soggetto associato)----------------------    
    
  IF cur_upd_sogg.movgest_tipo_code='I' THEN 
  
  raise notice 'cur_upd_sogg - movgest_tipo_code=I';

  

select distinct 
substring (b.classif_code from 1 for 6) macroagg 
into  macroaggegato_exists
from 
siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c,siac_t_movgest_ts d
where 
d.movgest_ts_id=a.movgest_ts_id 
and  d.movgest_ts_id=cur_upd_sogg.movgest_ts_id
and a.classif_id=b.classif_id
and c.classif_tipo_id=b.classif_tipo_id and c.classif_tipo_code like 'PDC%'
and (b.classif_code like 'U.1.04%' or b.classif_code like 'U.2.03%' or b.classif_code like 'U.2.04%' or 
b.classif_code like 'U.2.05%' or b.classif_code like 'U.3%' or b.classif_code like 'U.4.01%' or 
b.classif_code like 'U.4.02%' or b.classif_code like 'U.4.03%' or b.classif_code like 'U.4.04%' or 
b.classif_code like 'U.5%' or b.classif_code like 'U.7.01%' or b.classif_code like 'U.7.02%')
and a.data_cancellazione is NULL
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and now() BETWEEN a.validita_inizio and COALESCE(a.validita_fine,now());


      if macroaggegato_exists is not null then
      
        raise notice 'cur_upd_sogg - macroaggegato_exists ';

  --------------------------AMBITO_FIN INIZIO-----------------------------------
        for cur_regmovfin in --LOOP AMBITO_FIN
        select b.classif_id,
               e.ambito_id
        from siac_r_movgest_class a,
             siac_t_class b,
             siac_d_class_tipo c,
             siac_t_movgest_ts d,
             siac_d_ambito e
        where a.classif_id = b.classif_id and
              b.classif_tipo_id = c.classif_tipo_id and
              c.classif_tipo_code like 'PDC%' and
              d.movgest_ts_id = a.movgest_ts_id and
              d.movgest_ts_id = cur_upd_sogg.movgest_ts_id and
              e.ente_proprietario_id = b.ente_proprietario_id and
              a.data_cancellazione is null and
              b.data_cancellazione is null and
              c.data_cancellazione is null and
              d.data_cancellazione is null and
              e.data_cancellazione is null and
              e.ambito_code = 'AMBITO_FIN' and
              now() between a.validita_inizio and COALESCE(a.validita_fine,now())
              
        loop
        
         raise notice 'cur_upd_sogg - loop cur_regmovfin';

          INSERT INTO siac.siac_t_reg_movfin(classif_id_iniziale,classif_id_aggiornato, bil_id, validita_inizio,ente_proprietario_id, login_operazione, ambito_id)
          values (cur_regmovfin.classif_id,cur_regmovfin.classif_id, cur_upd_sogg.bil_id, valid_inizio,
            ente_proprietario_new_id, login_oper, cur_regmovfin.ambito_id)
            returning regmovfin_id
          into _regmovfin_id;

          INSERT INTO siac.siac_r_reg_movfin_stato(regmovfin_id,regmovfin_stato_id, validita_inizio, ente_proprietario_id, login_operazione)
          select _regmovfin_id,
                 b.regmovfin_stato_id,
                 valid_inizio,
                 ente_proprietario_new_id,
                 login_oper
          from siac_d_reg_movfin_stato b
          where b.regmovfin_stato_code = 'N' and
                b.ente_proprietario_id = ente_proprietario_new_id
                 and
              now() between b.validita_inizio and COALESCE(b.validita_fine,now());

          if cur_upd_sogg.movgest_ts_tipo_code='T' then
          
             raise notice 'cur_upd_sogg - movgest_ts_tipo_code=T';
            
          if macroaggegato_exists='U.4.02' or macroaggegato_exists='U.4.03' or macroaggegato_exists='U.4.04' or macroaggegato_exists='U.7.01'  THEN
          evento_code_reg_movfin:='IMP-PRG';
          else
          evento_code_reg_movfin:='IMP-INS';
          end if; 
       
            INSERT INTO siac.siac_r_evento_reg_movfin(regmovfin_id, evento_id,campo_pk_id, validita_inizio, ente_proprietario_id, login_operazione)
            select _regmovfin_id,
                   a.evento_id,
                   cur_upd_sogg.movgest_id, --IMPEGNO
                   valid_inizio,
                   ente_proprietario_new_id,
                   login_oper
            from siac_d_evento a
            where 
                  a.ente_proprietario_id = ente_proprietario_new_id AND
                  a.evento_code = evento_code_reg_movfin--'IMP-INS'
                  and  now() between a.validita_inizio and COALESCE(a.validita_fine,now())
                  and a.data_cancellazione is null
                  ;
        
          else --movgest_ts_tipo_code='S'
          
           if macroaggegato_exists='U.4.02' or macroaggegato_exists='U.4.03' or macroaggegato_exists='U.4.04' or macroaggegato_exists='U.7.01'  THEN
          evento_code_reg_movfin:='SIM-PRG';
          else
          evento_code_reg_movfin:='SIM-INS';
          end if; 
          
             raise notice 'cur_upd_sogg movgest_ts_tipo_code=S';
        
            INSERT INTO siac.siac_r_evento_reg_movfin(regmovfin_id, evento_id,campo_pk_id, validita_inizio, ente_proprietario_id, login_operazione)
            select _regmovfin_id,
                   a.evento_id,
                   cur_upd_sogg.movgest_ts_id, --subimpegno
                   valid_inizio,
                   ente_proprietario_new_id,
                   login_oper
            from siac_d_evento a
             where a.ente_proprietario_id = ente_proprietario_new_id AND
                  a.evento_code = evento_code_reg_movfin--'SIM-INS'
                  and  now() between a.validita_inizio and COALESCE(a.validita_fine,now())
                  and a.data_cancellazione is null
                  ;
        
          end if; --movgest_ts_tipo_code='T' o movgest_ts_tipo_code='S'
        
          return next;
       
        end loop; --LOOP AMBITO_FIN
         _regmovfin_id:=null;
             raise notice 'fine ambito FIN';

  --------------------------AMBITO_GSA INIZIO-----------------------------------    

        select c.ambito_id
        into ambito_id_gsa
        from siac_r_movgest_ts_attr a,
             siac_t_attr b,
             siac_d_ambito c
        where a.movgest_ts_id = cur_upd_sogg.movgest_ts_id and
              a.attr_id = b.attr_id and
              b.attr_code = 'FlagAttivaGsa' and
              c.ente_proprietario_id = b.ente_proprietario_id and
              c.ambito_code = 'AMBITO_GSA' and
              a."boolean" = 'S' and
              now() between a.validita_inizio and COALESCE(a.validita_fine,now())
              and a.data_cancellazione is null
              and b.data_cancellazione is null
              and c.data_cancellazione is null
        ;
        
        IF ambito_id_gsa is not null then
        
         raise notice 'ambito GSA';

          -- loop GSA
          for cur_regmovfin_gsa in select b.classif_id,
                e.ambito_id
         from siac_r_movgest_class a,
              siac_t_class b,
              siac_d_class_tipo c,
              siac_t_movgest_ts d,
              siac_d_ambito e
         where a.classif_id = b.classif_id and
               b.classif_tipo_id = c.classif_tipo_id  and
               c.classif_tipo_code like 'PDC%' and
               d.movgest_ts_id = a.movgest_ts_id and
               d.movgest_ts_id = cur_upd_sogg.movgest_ts_id and
               e.ente_proprietario_id =  b.ente_proprietario_id and
               a.data_cancellazione is null and
               b.data_cancellazione is null and
               c.data_cancellazione is null and
               d.data_cancellazione is null and
               e.data_cancellazione is null and
               e.ambito_code = 'AMBITO_GSA' and
              now() between a.validita_inizio and COALESCE(a.validita_fine,now())
          loop
 			
          raise notice 'cur_regmovfin_gsa - cur_regmovfin_gsa';

          INSERT INTO siac.siac_t_reg_movfin(classif_id_iniziale,classif_id_aggiornato,bil_id,validita_inizio,ente_proprietario_id,login_operazione,ambito_id)
          values (cur_regmovfin_gsa.classif_id,cur_regmovfin_gsa.classif_id,cur_upd_sogg.bil_id,valid_inizio,ente_proprietario_new_id,login_oper,cur_regmovfin_gsa.ambito_id)
          returning regmovfin_id into _regmovfin_id
          ;

          INSERT INTO siac.siac_r_reg_movfin_stato(regmovfin_id,regmovfin_stato_id, validita_inizio, ente_proprietario_id, login_operazione)
          select _regmovfin_id,
                 b.regmovfin_stato_id,
                 valid_inizio,
                 ente_proprietario_new_id,
                 login_oper
          from siac_d_reg_movfin_stato b
          where b.regmovfin_stato_code = 'N' and
                b.ente_proprietario_id = ente_proprietario_new_id
                and now() between b.validita_inizio and COALESCE(b.validita_fine,now())
                and b.data_cancellazione is null
                ;

          IF cur_upd_sogg.movgest_ts_tipo_code='T' then
          
          if macroaggegato_exists='U.4.02' or macroaggegato_exists='U.4.03' or macroaggegato_exists='U.4.04' or macroaggegato_exists='U.7.01'  THEN
          evento_code_reg_movfin:='IMP-PRG';
          else
          evento_code_reg_movfin:='IMP-INS';
          end if; 
          
          raise notice 'cur_regmovfin_gsamovgest_ts_tipo_code=T';
              
            INSERT INTO siac.siac_r_evento_reg_movfin(regmovfin_id, evento_id,campo_pk_id, validita_inizio, ente_proprietario_id, login_operazione)
            select _regmovfin_id,
                   a.evento_id,
                   cur_upd_sogg.movgest_id,
                   valid_inizio,
                   ente_proprietario_new_id,
                   login_oper
            from siac_d_evento a
            where a.ente_proprietario_id = ente_proprietario_new_id AND
                  a.evento_code = evento_code_reg_movfin--'IMP-INS'
                  and now() between a.validita_inizio and COALESCE(a.validita_fine,now())
                  and a.data_cancellazione is null
                  ;
              
          ELSE --movgest_ts_tipo_code='S'
          if macroaggegato_exists='U.4.02' or macroaggegato_exists='U.4.03' or macroaggegato_exists='U.4.04' or macroaggegato_exists='U.7.01'  THEN
          evento_code_reg_movfin:='SIM-PRG';
          else
          evento_code_reg_movfin:='SIM-INS';
          end if; 
          raise notice 'cur_regmovfin_gsa - movgest_ts_tipo_code=S';
              
            INSERT INTO siac.siac_r_evento_reg_movfin(regmovfin_id, evento_id, campo_pk_id, validita_inizio, ente_proprietario_id, login_operazione)
            select _regmovfin_id,
                   a.evento_id,
                   cur_upd_sogg.movgest_id,
                   valid_inizio,
                   ente_proprietario_new_id,
                   login_oper
            from siac_d_evento a
            where a.ente_proprietario_id = ente_proprietario_new_id AND
                  a.evento_code = evento_code_reg_movfin--'SIM-INS'
                  and now() between a.validita_inizio and COALESCE(a.validita_fine,now())
                  and a.data_cancellazione is null;
                  
          END IF; --movgest_ts_tipo_code='T' o movgest_ts_tipo_code='S'
              
          RETURN NEXT;
              
          END LOOP; --loop GSA
        _regmovfin_id:=null;    
        END IF;	--ambito GSA not null
  --------------------------GSA FINE IMPEGNO-----------------------------------           
          
      END IF;--elem_id_exists<>0

	ELSE --cur_upd_sogg.movgest_tipo_code='A'

		raise notice 'cur_regmovfin - accertamento';
        raise notice 'cur_regmovfin - cur_upd_sogg.movgest_tipo_code %', cur_upd_sogg.movgest_tipo_code;
	
      for cur_regmovfin_acc in --LOOP AMBITO_FIN
        select b.classif_id,
               e.ambito_id
        from siac_r_movgest_class a,
             siac_t_class b,
             siac_d_class_tipo c,
             siac_t_movgest_ts d,
             siac_d_ambito e,
             siac_r_movgest_ts_attr f ,siac_t_attr g
             --, siac_r_movgest_ts_stato h, siac_d_movgest_stato i
        where a.classif_id = b.classif_id and
              b.classif_tipo_id = c.classif_tipo_id and
              c.classif_tipo_code like 'PDC%' and
              d.movgest_ts_id = a.movgest_ts_id and
              d.movgest_ts_id = cur_upd_sogg.movgest_ts_id and
              e.ente_proprietario_id = b.ente_proprietario_id and
              a.data_cancellazione is null and
              b.data_cancellazione is null and
              c.data_cancellazione is null and
              d.data_cancellazione is null and
              e.data_cancellazione is null and
              e.ambito_code = 'AMBITO_FIN' and 
              now() between a.validita_inizio and COALESCE(a.validita_fine,now()) and 
              f.movgest_ts_id=d.movgest_ts_id and 
              g.attr_id=f.attr_id and 
              g.attr_code='FlagCollegamentoAccertamentoFattura' and 
              f."boolean"='N' and 
              now() between f.validita_inizio and COALESCE(f.validita_fine,now()) and
              --h.movgest_ts_id=d.movgest_ts_id and
              --i.movgest_stato_id=h.movgest_stato_id and 
              --now() between h.validita_inizio and COALESCE(h.validita_fine,now()) and
              --i.movgest_stato_code='D' and
              f.data_cancellazione is null and
              g.data_cancellazione is null 
              --and h.data_cancellazione is null and
              --i.data_cancellazione is null 
        loop

          INSERT INTO siac.siac_t_reg_movfin(classif_id_iniziale,classif_id_aggiornato,bil_id,validita_inizio,ente_proprietario_id,login_operazione,ambito_id)
          values (cur_regmovfin_acc.classif_id,cur_regmovfin_acc.classif_id,cur_upd_sogg.bil_id,valid_inizio,ente_proprietario_new_id,login_oper,cur_regmovfin_acc.ambito_id)
          returning regmovfin_id into _regmovfin_id
          ;

          INSERT INTO siac.siac_r_reg_movfin_stato(regmovfin_id,regmovfin_stato_id, validita_inizio, ente_proprietario_id, login_operazione)
          select _regmovfin_id,
                 b.regmovfin_stato_id,
                 valid_inizio,
                 ente_proprietario_new_id,
                 login_oper
          from siac_d_reg_movfin_stato b
          where b.regmovfin_stato_code = 'N' and
                b.ente_proprietario_id = ente_proprietario_new_id
                  and now() between b.validita_inizio and COALESCE(b.validita_fine,now())
                  and b.data_cancellazione is null;

          if cur_upd_sogg.movgest_ts_tipo_code='T' then
       
      		raise notice 'cur_regmovfin_acc - movgest_ts_tipo_code=T';
            INSERT INTO siac.siac_r_evento_reg_movfin(regmovfin_id, evento_id, campo_pk_id, validita_inizio, ente_proprietario_id, login_operazione)
            select _regmovfin_id,
                   a.evento_id,
                   cur_upd_sogg.movgest_id, --IMPEGNO
                   valid_inizio,
                   ente_proprietario_new_id,
                   login_oper
            from siac_d_evento a
            where a.ente_proprietario_id = ente_proprietario_new_id AND
                  a.evento_code = 'ACC-INS'
                  and now() between a.validita_inizio and COALESCE(a.validita_fine,now())
                  and a.data_cancellazione is null;
                  
        
          else --movgest_ts_tipo_code='S'
          
            raise notice 'cur_regmovfin_acc - movgest_ts_tipo_code=S';
        
            INSERT INTO siac.siac_r_evento_reg_movfin(regmovfin_id, evento_id, campo_pk_id, validita_inizio, ente_proprietario_id, login_operazione)
            select _regmovfin_id,
                   a.evento_id,
                   cur_upd_sogg.movgest_ts_id, --subimpegno
                   valid_inizio,
                   ente_proprietario_new_id,
                   login_oper
            from siac_d_evento a
            where a.ente_proprietario_id = ente_proprietario_new_id AND
                  a.evento_code = 'SAC-INS'
                  and now() between a.validita_inizio and COALESCE(a.validita_fine,now())
                  and a.data_cancellazione is null
                  ;
        
          end if; --movgest_ts_tipo_code='T' o movgest_ts_tipo_code='S'
        
          return next;
                _regmovfin_id:=null;
        end loop; --LOOP AMBITO_FIN accertamento

  --------------------------AMBITO_GSA INIZIO-----------------------------------    

        select c.ambito_id
        into ambito_id_gsa
        from siac_r_movgest_ts_attr a,
             siac_t_attr b,
             siac_d_ambito c
        where a.movgest_ts_id = cur_upd_sogg.movgest_ts_id and
              a.attr_id = b.attr_id and
              b.attr_code = 'FlagAttivaGsa' and
              c.ente_proprietario_id = b.ente_proprietario_id and
              c.ambito_code = 'AMBITO_GSA' and
              a."boolean" = 'S'
              and now() between a.validita_inizio and COALESCE(a.validita_fine,now())
              and a.data_cancellazione is null
              and b.data_cancellazione is null
              and c.data_cancellazione is null
        ;
        
        IF ambito_id_gsa is not null then
     	
        raise notice 'gsa accertamento';
          -- loop GSA
          for cur_regmovfin_gsa_acc in 
          select b.classif_id,e.ambito_id
          from siac_r_movgest_class a,
          siac_t_class b,
          siac_d_class_tipo c,
          siac_t_movgest_ts d,
          siac_d_ambito e,
          siac_r_movgest_ts_attr f ,siac_t_attr g
          --,siac_r_movgest_ts_stato h, siac_d_movgest_stato i
          where a.classif_id = b.classif_id and
          b.classif_tipo_id = c.classif_tipo_id and
          c.classif_tipo_code like 'PDC%' and
          d.movgest_ts_id = a.movgest_ts_id and
          d.movgest_ts_id = cur_upd_sogg.movgest_ts_id and
          e.ente_proprietario_id = b.ente_proprietario_id and
          a.data_cancellazione is null and
          b.data_cancellazione is null and
          c.data_cancellazione is null and
          d.data_cancellazione is null and
          e.data_cancellazione is null and
          e.ambito_code = 'AMBITO_GSA' and 
          now() between a.validita_inizio and COALESCE(a.validita_fine,now()) and 
          f.movgest_ts_id=d.movgest_ts_id and 
          g.attr_id=f.attr_id and 
          g.attr_code='FlagCollegamentoAccertamentoFattura' and 
          f."boolean"='N' and 
          now() between f.validita_inizio and COALESCE(f.validita_fine,now()) and
          --h.movgest_ts_id=d.movgest_ts_id and
          --i.movgest_stato_id=h.movgest_stato_id and 
          --now() between h.validita_inizio and COALESCE(h.validita_fine,now()) and
          --i.movgest_stato_code='D' and
          f.data_cancellazione is null and
          g.data_cancellazione is null
          --and h.data_cancellazione is null and
          --i.data_cancellazione is null 
         loop

          INSERT INTO siac.siac_t_reg_movfin(classif_id_iniziale,classif_id_aggiornato,bil_id,validita_inizio,ente_proprietario_id,login_operazione,ambito_id)
          values (cur_regmovfin_gsa_acc.classif_id,cur_regmovfin_gsa_acc.classif_id,cur_upd_sogg.bil_id,valid_inizio,ente_proprietario_new_id,login_oper,cur_regmovfin_gsa_acc.ambito_id)
          returning regmovfin_id into _regmovfin_id
          ;

          INSERT INTO siac.siac_r_reg_movfin_stato(regmovfin_id, regmovfin_stato_id,  validita_inizio, ente_proprietario_id, login_operazione)
          select _regmovfin_id,
                 b.regmovfin_stato_id,
                 valid_inizio,
                 ente_proprietario_new_id,
                 login_oper
          from siac_d_reg_movfin_stato b
          where b.regmovfin_stato_code = 'N' and
                b.ente_proprietario_id = ente_proprietario_new_id
                and now() between b.validita_inizio and COALESCE(b.validita_fine,now())
                and b.data_cancellazione is null;

          IF cur_upd_sogg.movgest_ts_tipo_code='T' then
                   raise notice 'cur_regmovfin_gsa_acc - movgest_ts_tipo_code=T';
            INSERT INTO siac.siac_r_evento_reg_movfin(regmovfin_id, evento_id, campo_pk_id, validita_inizio, ente_proprietario_id, login_operazione)
            select _regmovfin_id,
                   a.evento_id,
                   cur_upd_sogg.movgest_id,
                   valid_inizio,
                   ente_proprietario_new_id,
                   login_oper
            from siac_d_evento a
            where a.ente_proprietario_id = ente_proprietario_new_id AND
                  a.evento_code = 'ACC-INS'
                  and now() between a.validita_inizio and COALESCE(a.validita_fine,now())
                  and a.data_cancellazione is null
                  ;
              
          ELSE --movgest_ts_tipo_code='S'
                   raise notice 'cur_regmovfin_gsa_acc - movgest_ts_tipo_code=S';
            INSERT INTO siac.siac_r_evento_reg_movfin(regmovfin_id, evento_id, campo_pk_id, validita_inizio, ente_proprietario_id, login_operazione)
            select _regmovfin_id,
                   a.evento_id,
                   cur_upd_sogg.movgest_id,
                   valid_inizio,
                   ente_proprietario_new_id,
                   login_oper
            from siac_d_evento a
            where a.ente_proprietario_id = ente_proprietario_new_id AND
                  a.evento_code = 'SAC-INS'
                  and now() between a.validita_inizio and COALESCE(a.validita_fine,now())
                  and a.data_cancellazione is null
                  ;
  			
          END IF; --movgest_ts_tipo_code='T' o movgest_ts_tipo_code='S'
              
          RETURN NEXT;
              
          END LOOP; --loop GSA
        _regmovfin_id:=null;
        --       raise notice 'fine GSA';
             
        END IF;	--ambito GSA not null


	END IF; --cur_upd_sogg.movgest_tipo_code='I'
       

       

 END LOOP; --cur_upd_sogg


--------------------------IMPEGNO FINE-----------------------------------

--NESSUN SOGGETTO ASSOCIATO
  for cur_upd_nosogg in
  select tss.movgest_stato_r_id,
         ts.movgest_ts_id,
         tt.movgest_ts_tipo_code,
         b.bil_id,
         mg.movgest_id,
         tipom.movgest_tipo_code
  from siac_t_atto_amm aa,
       siac_r_movgest_ts_atto_amm mga,
       siac_t_movgest_ts ts,
       siac_t_movgest mg,
       siac_r_movgest_ts_stato tss,
       siac_d_movgest_stato mgs,
       siac_t_bil b,
       siac_d_fase_operativa fo,
       siac_r_bil_fase_operativa bfo,
       siac_d_movgest_ts_tipo tt,
       siac_d_movgest_tipo tipom
  where mga.attoamm_id = aa.attoamm_id and
        ts.movgest_ts_id = mga.movgest_ts_id and
        mg.movgest_id = ts.movgest_id and
        tss.movgest_ts_id = ts.movgest_ts_id and
        mgs.movgest_stato_id = tss.movgest_stato_id and
        mgs.movgest_stato_code <> 'A' and
        b.bil_id = mg.bil_id and
        bfo.fase_operativa_id = fo.fase_operativa_id and
        bfo.bil_id = b.bil_id and
        fo.fase_operativa_code <> 'C' and
        aa.attoamm_id = attoamm_id_in and
        tt.movgest_ts_tipo_id = ts.movgest_ts_tipo_id and
        mgs.movgest_stato_code = 'P' and
        tipom.movgest_tipo_id = mg.movgest_tipo_id 
        and now() between tss.validita_inizio and COALESCE(tss.validita_fine,now())
        and now() between mga.validita_inizio and COALESCE(mga.validita_fine,now())
        and now() between bfo.validita_inizio and COALESCE(bfo.validita_fine,now())
        and aa.data_cancellazione is null
        and mga.data_cancellazione is null
        and ts.data_cancellazione is null
        and mg.data_cancellazione is null
        and tss.data_cancellazione is null
        and mgs.data_cancellazione is null
        and b.data_cancellazione is null
        and fo.data_cancellazione is null
        and bfo.data_cancellazione is null
        and tipom.data_cancellazione is null
        and tt.data_cancellazione is null
        and
        not exists (
                     select 1
                     from siac_r_movgest_ts_sog sog
                     where sog.movgest_ts_id = ts.movgest_ts_id
        )
        and 
       	not exists (
               select 1
               from siac_r_movgest_ts_sogclasse sogcl
               where  sogcl.movgest_ts_id = ts.movgest_ts_id
      	)
        
        
  LOOP

    update siac_r_movgest_ts_stato set 
    validita_fine=valid_fine, data_modifica=valid_fine, 
    data_cancellazione=valid_fine,login_operazione=login_operazione||' - '||'fnc_siac_atto_amm_aggiorna_stato_movgest'
    where movgest_stato_r_id=cur_upd_nosogg.movgest_stato_r_id;
    

  

    INSERT INTO siac_r_movgest_ts_stato (movgest_ts_id,movgest_stato_id,validita_inizio,ente_proprietario_id,data_creazione,login_operazione)
    VALUES (cur_upd_nosogg.movgest_ts_id,stato_new_id_no_sog,valid_inizio,ente_proprietario_new_id,valid_inizio,login_oper);

  raise notice 'no sogg';
  
    
        
 END LOOP;
   
  

 esito:='OK';
  
         
  
else --se stato <>'DEFINITIVO'
  esito:='KO';
  _regmovfin_id:=-1;
end if;




raise notice 'nuova richiesta';
---nuova richiesta di S.Torta, scritture in caso di atto amm collegato a modifiche
--per ogni tipo di evento occorre recuperare l'entità associata





--modifiche su movgest (importo)

/*query:='select 
f.mod_stato_id mod_id, f.ente_proprietario_id movgest_ts_id
from siac_d_modifica_stato f,siac_r_modifica_stato b, siac_t_modifica a,siac_t_atto_amm g,
siac_t_movgest_ts_det_mod c,siac_t_movgest_ts e,siac_r_atto_amm_stato h,siac_d_atto_amm_stato i
,siac_t_movgest l,siac_d_movgest_tipo m,
siac_d_movgest_ts_tipo n,siac_d_ambito o,
siac_r_movgest_class p,siac_t_class q,siac_d_class_tipo r 
where 
f.mod_stato_id = b.mod_stato_id and a.mod_id=b.mod_id and a.attoamm_id = g.attoamm_id and
c.mod_stato_r_id = b.mod_stato_r_id and e.movgest_ts_id = c.movgest_ts_id and
g.attoamm_id = h.attoamm_id and h.attoamm_stato_id = i.attoamm_stato_id and
l.movgest_id=e.movgest_id and m.movgest_tipo_id=l.movgest_tipo_id 
and n.movgest_ts_tipo_id=e.movgest_ts_tipo_id and
o.ente_proprietario_id=a.ente_proprietario_id 
and o.ambito_code=''AMBITO_FIN'' and
p.movgest_ts_id=e.movgest_ts_id and q.classif_id=p.classif_id 
and r.classif_tipo_id=q.classif_tipo_id and
r.classif_tipo_code like ''%PDC%'' and 
now() between b.validita_inizio and coalesce(b.validita_fine, now()) 
and now() between h.validita_inizio and coalesce(h.validita_fine, now()) 
and now() between p.validita_inizio and coalesce(p.validita_fine, now()) and
a.data_cancellazione is null and b.data_cancellazione is null 
and c.data_cancellazione is null and e.data_cancellazione is null 
and f.data_cancellazione is null and g.data_cancellazione is null 
and i.data_cancellazione is null 
and l.data_cancellazione is null and m.data_cancellazione is null 
and n.data_cancellazione is null and o.data_cancellazione is null 
and p.data_cancellazione is null and q.data_cancellazione is null 
and r.data_cancellazione is null and
--i.attoamm_stato_code=''DEFINITIVO'' and
--r.data_cancellazione is null and
a.attoamm_id='||attoamm_id_in||' and
 f.mod_stato_code = '''||mod_stato_code_in||''' '
;*/



--modifica impegno
for cur_mod_movgest_imp in --execute query
select tb.* from (
with mod as (
select 
a.mod_id,
c.movgest_ts_id, m.movgest_tipo_code,n.movgest_ts_tipo_code,
 m.movgest_tipo_code||n.movgest_ts_tipo_code tipo_movgest,
o.ambito_id,q.classif_id, l.bil_id
from siac_t_modifica a, 
siac_r_modifica_stato b,
siac_t_movgest_ts_det_mod c, 
siac_t_movgest_ts e, siac_d_modifica_stato f, siac_t_atto_amm g,
siac_r_atto_amm_stato h, siac_d_atto_amm_stato i, 
siac_t_movgest l,
siac_d_movgest_tipo m,siac_d_movgest_ts_tipo n, siac_d_ambito o,
siac_r_movgest_class p, siac_t_class q,siac_d_class_tipo r
where
f.mod_stato_code = mod_stato_code_in
--and i.attoamm_stato_code = 'DEFINITIVO' -- atto provvisorio
and a.mod_id = b.mod_id
and c.mod_stato_r_id = b.mod_stato_r_id
and e.movgest_ts_id = c.movgest_ts_id
and f.mod_stato_id = b.mod_stato_id
and a.attoamm_id = g.attoamm_id
and g.attoamm_id = h.attoamm_id
and h.attoamm_stato_id = i.attoamm_stato_id
and l.movgest_id=e.movgest_id
and m.movgest_tipo_id=l.movgest_tipo_id
and n.movgest_ts_tipo_id=e.movgest_ts_tipo_id
and a.attoamm_id=attoamm_id_in
and o.ente_proprietario_id=a.ente_proprietario_id
and o.ambito_code='AMBITO_FIN'
and p.movgest_ts_id=e.movgest_ts_id
and q.classif_id=p.classif_id
and r.classif_tipo_id=q.classif_tipo_id
and r.classif_tipo_code like '%PDC%'
and now() between b.validita_inizio and coalesce(b.validita_fine, now())
and now() between h.validita_inizio and coalesce(h.validita_fine, now())
and now() between p.validita_inizio and coalesce(p.validita_fine, now())
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
--and h.data_cancellazione is null
and i.data_cancellazione is null
and l.data_cancellazione is null
and m.data_cancellazione is null
and n.data_cancellazione is null
and o.data_cancellazione is null
and p.data_cancellazione is null
and q.data_cancellazione is null
and r.data_cancellazione is null)
, /*condimp as (select distinct 
          d.movgest_ts_id
          from 
          siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c,siac_t_movgest_ts d
          where 
          d.movgest_ts_id=a.movgest_ts_id 
          --and  d.movgest_ts_id=cur_mod_movgest.movgest_ts_id
          and a.classif_id=b.classif_id
          and c.classif_tipo_id=b.classif_tipo_id and c.classif_tipo_code like 'PDC%'
          and (b.classif_code like 'U.1.04%' or b.classif_code like 'U.2.03%' or b.classif_code like 'U.2.04%' or 
          b.classif_code like 'U.2.05%' or b.classif_code like 'U.3%' or b.classif_code like 'U.4.01%' or 
          b.classif_code like 'U.4.02%' or b.classif_code like 'U.4.03%' or b.classif_code like 'U.4.04%' or 
          b.classif_code like 'U.5%' or b.classif_code like 'U.7.01%' or b.classif_code like 'U.7.02%')
          and a.data_cancellazione is NULL
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and now() BETWEEN a.validita_inizio and COALESCE(a.validita_fine,now())
          --soggetto collegato
          and ( 
               (    exists (
                             select 1
                             from siac_r_movgest_ts_sog sog
                             where sog.movgest_ts_id = a.movgest_ts_id
                           )
                ) or 
                (    
                    exists (
                             select 1
                             from siac_r_movgest_ts_sogclasse sogcl
                             where  sogcl.movgest_ts_id = a.movgest_ts_id
                    )
                ))    )     */
condimp as (
select tb.movgest_ts_id from (
with aa as (select distinct 
          d.movgest_ts_id
          from 
          siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c,siac_t_movgest_ts d
          where 
          d.movgest_ts_id=a.movgest_ts_id 
          --and  d.movgest_ts_id=cur_mod_movgest.movgest_ts_id
          and a.classif_id=b.classif_id
          and c.classif_tipo_id=b.classif_tipo_id and c.classif_tipo_code like 'PDC%'
          and (b.classif_code like 'U.1.04%' or b.classif_code like 'U.2.03%' or b.classif_code like 'U.2.04%' or 
          b.classif_code like 'U.2.05%' or b.classif_code like 'U.3%' or b.classif_code like 'U.4.01%' or 
          b.classif_code like 'U.4.02%' or b.classif_code like 'U.4.03%' or b.classif_code like 'U.4.04%' or 
          b.classif_code like 'U.5%' or b.classif_code like 'U.7.01%' or b.classif_code like 'U.7.02%')
          and a.data_cancellazione is NULL
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and now() BETWEEN a.validita_inizio and COALESCE(a.validita_fine,now())),
bb as (select movgest_ts_id from siac_r_movgest_ts_sog a
where a.ente_proprietario_id =ente_proprietario_new_id
UNION
select movgest_ts_id from siac_r_movgest_ts_sogclasse b
where b.ente_proprietario_id =ente_proprietario_new_id
)
select aa.movgest_ts_id from aa where exists (select 1 from bb where bb.movgest_ts_id=aa.movgest_ts_id)          
) as tb        
        )                
select mod.* from mod join condimp 
on mod.movgest_ts_id=condimp.movgest_ts_id    
) as tb            
loop

--raise notice 'dentro loop cur_mod_movgest';


--mod impegno FIN
      if cur_mod_movgest_imp.tipo_movgest='IT' then --impegno testata
          evento_code_reg_movfin:='MIM-INS-I';
      elsif cur_mod_movgest_imp.tipo_movgest='IS' then --impegno sub
          evento_code_reg_movfin:='MSI-INS-I';
      end if;
      
      
      INSERT INTO siac.siac_t_reg_movfin
(classif_id_iniziale,classif_id_aggiornato, bil_id, 
validita_inizio,ente_proprietario_id, login_operazione, ambito_id)
values (cur_mod_movgest_imp.classif_id,cur_mod_movgest_imp.classif_id,cur_mod_movgest_imp.bil_id, valid_inizio,
            ente_proprietario_new_id, login_oper, cur_mod_movgest_imp.ambito_id)
            returning regmovfin_id
into _regmovfin_id;



raise notice 'finimp:%', _regmovfin_id;

INSERT INTO siac.siac_r_reg_movfin_stato
(regmovfin_id,regmovfin_stato_id, validita_inizio, ente_proprietario_id, login_operazione)
select _regmovfin_id,
b.regmovfin_stato_id,
valid_inizio,
ente_proprietario_new_id,
login_oper
from siac_d_reg_movfin_stato b
where b.regmovfin_stato_code = 'N' and
b.ente_proprietario_id = ente_proprietario_new_id
and
now() between b.validita_inizio and COALESCE(b.validita_fine,now());


       
INSERT INTO siac.siac_r_evento_reg_movfin
(regmovfin_id, evento_id,campo_pk_id, validita_inizio, ente_proprietario_id, login_operazione)
select _regmovfin_id,
a.evento_id,
cur_mod_movgest_imp.mod_id,
valid_inizio,
ente_proprietario_new_id,
login_oper
from siac_d_evento a
where 
a.ente_proprietario_id = ente_proprietario_new_id AND
a.evento_code = evento_code_reg_movfin
and  now() between a.validita_inizio and COALESCE(a.validita_fine,now())
and a.data_cancellazione is null
;
return next;

end loop;
        _regmovfin_id:=null;
        
        
--mod accertamento FIN
for cur_mod_movgest_acc in 
select tb.* from (
with mod as (
select 
a.mod_id,
c.movgest_ts_id, m.movgest_tipo_code,n.movgest_ts_tipo_code,
 m.movgest_tipo_code||n.movgest_ts_tipo_code tipo_movgest,
o.ambito_id,q.classif_id, l.bil_id
from siac_t_modifica a, 
siac_r_modifica_stato b,
siac_t_movgest_ts_det_mod c, 
siac_t_movgest_ts e, siac_d_modifica_stato f, siac_t_atto_amm g,
siac_r_atto_amm_stato h, siac_d_atto_amm_stato i, 
siac_t_movgest l,
siac_d_movgest_tipo m,siac_d_movgest_ts_tipo n, siac_d_ambito o,
siac_r_movgest_class p, siac_t_class q,siac_d_class_tipo r
where
f.mod_stato_code = mod_stato_code_in
--and i.attoamm_stato_code = 'DEFINITIVO' -- atto provvisorio
and a.mod_id = b.mod_id
and c.mod_stato_r_id = b.mod_stato_r_id
and e.movgest_ts_id = c.movgest_ts_id
and f.mod_stato_id = b.mod_stato_id
and a.attoamm_id = g.attoamm_id
and g.attoamm_id = h.attoamm_id
and h.attoamm_stato_id = i.attoamm_stato_id
and l.movgest_id=e.movgest_id
and m.movgest_tipo_id=l.movgest_tipo_id
and n.movgest_ts_tipo_id=e.movgest_ts_tipo_id
and a.attoamm_id=attoamm_id_in
and o.ente_proprietario_id=a.ente_proprietario_id
and o.ambito_code='AMBITO_FIN'
and p.movgest_ts_id=e.movgest_ts_id
and q.classif_id=p.classif_id
and r.classif_tipo_id=q.classif_tipo_id
and r.classif_tipo_code like '%PDC%'
and now() between b.validita_inizio and coalesce(b.validita_fine, now())
and now() between h.validita_inizio and coalesce(h.validita_fine, now())
and now() between p.validita_inizio and coalesce(p.validita_fine, now())
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
--and h.data_cancellazione is null
and i.data_cancellazione is null
and l.data_cancellazione is null
and m.data_cancellazione is null
and n.data_cancellazione is null
and o.data_cancellazione is null
and p.data_cancellazione is null
and q.data_cancellazione is null
and r.data_cancellazione is null)
, condacc as (select distinct d.movgest_ts_id
        from siac_r_movgest_class a,
             siac_t_class b,
             siac_d_class_tipo c,
             siac_t_movgest_ts d,
             siac_d_ambito e,
             siac_r_movgest_ts_attr f ,siac_t_attr g
             --,siac_r_movgest_ts_stato h, siac_d_movgest_stato i
        where a.classif_id = b.classif_id and
              b.classif_tipo_id = c.classif_tipo_id and
              c.classif_tipo_code like 'PDC%' and
              d.movgest_ts_id = a.movgest_ts_id and
              --d.movgest_ts_id = cur_mod_movgest.movgest_ts_id and
              e.ente_proprietario_id = b.ente_proprietario_id and
              a.data_cancellazione is null and
              b.data_cancellazione is null and
              c.data_cancellazione is null and
              d.data_cancellazione is null and
              e.data_cancellazione is null and
              e.ambito_code = 'AMBITO_FIN' and 
              now() between a.validita_inizio and COALESCE(a.validita_fine,now()) and 
              f.movgest_ts_id=d.movgest_ts_id and 
              g.attr_id=f.attr_id and 
              g.attr_code='FlagCollegamentoAccertamentoFattura' and 
              f."boolean"='N' and 
              now() between f.validita_inizio and COALESCE(f.validita_fine,now()) and
              --h.movgest_ts_id=d.movgest_ts_id and
              --i.movgest_stato_id=h.movgest_stato_id and 
              --now() between h.validita_inizio and COALESCE(h.validita_fine,now()) and
              --i.movgest_stato_code='D' and
              f.data_cancellazione is null and
              g.data_cancellazione is null 
              -- and h.data_cancellazione is null and
              -- i.data_cancellazione is null
              )
select mod.* from mod join condacc
on mod.movgest_ts_id=condacc.movgest_ts_id) tb
loop

      if cur_mod_movgest_acc.tipo_movgest='AT' then --accertamento testata
        evento_code_reg_movfin:='MAC-INS-I';
      elsif cur_mod_movgest_acc.tipo_movgest='AS' then --accertamento sub
        evento_code_reg_movfin:='MSA-INS-I';
      end if;


      INSERT INTO siac.siac_t_reg_movfin
      (classif_id_iniziale,classif_id_aggiornato, bil_id, 
      validita_inizio,ente_proprietario_id, login_operazione, ambito_id)
      values (cur_mod_movgest_acc.classif_id,cur_mod_movgest_acc.classif_id,cur_mod_movgest_acc.bil_id, valid_inizio,
                  ente_proprietario_new_id, login_oper, cur_mod_movgest_acc.ambito_id)
                  returning regmovfin_id
      into _regmovfin_id;

    
      raise notice 'finimp:%', _regmovfin_id;

      INSERT INTO siac.siac_r_reg_movfin_stato
      (regmovfin_id,regmovfin_stato_id, validita_inizio, ente_proprietario_id, login_operazione)
      select _regmovfin_id,
      b.regmovfin_stato_id,
      valid_inizio,
      ente_proprietario_new_id,
      login_oper
      from siac_d_reg_movfin_stato b
      where b.regmovfin_stato_code = 'N' and
      b.ente_proprietario_id = ente_proprietario_new_id
      and
      now() between b.validita_inizio and COALESCE(b.validita_fine,now());


                 
      INSERT INTO siac.siac_r_evento_reg_movfin
      (regmovfin_id, evento_id,campo_pk_id, validita_inizio, ente_proprietario_id, login_operazione)
      select _regmovfin_id,
      a.evento_id,
      cur_mod_movgest_acc.mod_id,
      valid_inizio,
      ente_proprietario_new_id,
      login_oper
      from siac_d_evento a
      where 
      a.ente_proprietario_id = ente_proprietario_new_id AND
      a.evento_code = evento_code_reg_movfin
      and  now() between a.validita_inizio and COALESCE(a.validita_fine,now())
      and a.data_cancellazione is null
      ;

	  return next;

end loop; --fine accertamento fin
        _regmovfin_id:=null;
--------modifiche GSA------------------------------------------------------

--impegno GSA mod importo
for cur_mod_movgest_imp_gsa in
select tb.* from (
with mod as (
select 
a.mod_id,
c.movgest_ts_id, m.movgest_tipo_code,n.movgest_ts_tipo_code,
 m.movgest_tipo_code||n.movgest_ts_tipo_code tipo_movgest,
o.ambito_id,q.classif_id, l.bil_id
from siac_t_modifica a, 
siac_r_modifica_stato b,
siac_t_movgest_ts_det_mod c, 
siac_t_movgest_ts e, siac_d_modifica_stato f, siac_t_atto_amm g,
siac_r_atto_amm_stato h, siac_d_atto_amm_stato i, 
siac_t_movgest l,
siac_d_movgest_tipo m,siac_d_movgest_ts_tipo n, siac_d_ambito o,
siac_r_movgest_class p, siac_t_class q,siac_d_class_tipo r
where
f.mod_stato_code = mod_stato_code_in
--and i.attoamm_stato_code = 'DEFINITIVO' -- atto provvisorio
and a.mod_id = b.mod_id
and c.mod_stato_r_id = b.mod_stato_r_id
and e.movgest_ts_id = c.movgest_ts_id
and f.mod_stato_id = b.mod_stato_id
and a.attoamm_id = g.attoamm_id
and g.attoamm_id = h.attoamm_id
and h.attoamm_stato_id = i.attoamm_stato_id
and l.movgest_id=e.movgest_id
and m.movgest_tipo_id=l.movgest_tipo_id
and n.movgest_ts_tipo_id=e.movgest_ts_tipo_id
and a.attoamm_id=attoamm_id_in
and o.ente_proprietario_id=a.ente_proprietario_id
and o.ambito_code='AMBITO_GSA'
and p.movgest_ts_id=e.movgest_ts_id
and q.classif_id=p.classif_id
and r.classif_tipo_id=q.classif_tipo_id
and r.classif_tipo_code like '%PDC%'
and now() between b.validita_inizio and coalesce(b.validita_fine, now())
and now() between h.validita_inizio and coalesce(h.validita_fine, now())
and now() between p.validita_inizio and coalesce(p.validita_fine, now())
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
--and h.data_cancellazione is null
and i.data_cancellazione is null
and l.data_cancellazione is null
and m.data_cancellazione is null
and n.data_cancellazione is null
and o.data_cancellazione is null
and p.data_cancellazione is null
and q.data_cancellazione is null
and r.data_cancellazione is null)
, /*condimp as (select distinct 
          d.movgest_ts_id
          from 
          siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c,siac_t_movgest_ts d
          where 
          d.movgest_ts_id=a.movgest_ts_id 
          --and  d.movgest_ts_id=cur_mod_movgest.movgest_ts_id
          and a.classif_id=b.classif_id
          and c.classif_tipo_id=b.classif_tipo_id and c.classif_tipo_code like 'PDC%'
          and (b.classif_code like 'U.1.04%' or b.classif_code like 'U.2.03%' or b.classif_code like 'U.2.04%' or 
          b.classif_code like 'U.2.05%' or b.classif_code like 'U.3%' or b.classif_code like 'U.4.01%' or 
          b.classif_code like 'U.4.02%' or b.classif_code like 'U.4.03%' or b.classif_code like 'U.4.04%' or 
          b.classif_code like 'U.5%' or b.classif_code like 'U.7.01%' or b.classif_code like 'U.7.02%')
          and a.data_cancellazione is NULL
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and now() BETWEEN a.validita_inizio and COALESCE(a.validita_fine,now())
          --soggetto collegato
          and ( 
               (    exists (
                             select 1
                             from siac_r_movgest_ts_sog sog
                             where sog.movgest_ts_id = a.movgest_ts_id
                           )
                ) or 
                (    
                    exists (
                             select 1
                             from siac_r_movgest_ts_sogclasse sogcl
                             where  sogcl.movgest_ts_id = a.movgest_ts_id
                    )
                ))    )*/
condimp as (
select tb.movgest_ts_id from (
with aa as (select distinct 
          d.movgest_ts_id
          from 
          siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c,siac_t_movgest_ts d
          where 
          d.movgest_ts_id=a.movgest_ts_id 
          --and  d.movgest_ts_id=cur_mod_movgest.movgest_ts_id
          and a.classif_id=b.classif_id
          and c.classif_tipo_id=b.classif_tipo_id and c.classif_tipo_code like 'PDC%'
          and (b.classif_code like 'U.1.04%' or b.classif_code like 'U.2.03%' or b.classif_code like 'U.2.04%' or 
          b.classif_code like 'U.2.05%' or b.classif_code like 'U.3%' or b.classif_code like 'U.4.01%' or 
          b.classif_code like 'U.4.02%' or b.classif_code like 'U.4.03%' or b.classif_code like 'U.4.04%' or 
          b.classif_code like 'U.5%' or b.classif_code like 'U.7.01%' or b.classif_code like 'U.7.02%')
          and a.data_cancellazione is NULL
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and now() BETWEEN a.validita_inizio and COALESCE(a.validita_fine,now())),
bb as (select movgest_ts_id from siac_r_movgest_ts_sog a
where a.ente_proprietario_id =ente_proprietario_new_id
UNION
select movgest_ts_id from siac_r_movgest_ts_sogclasse b
where b.ente_proprietario_id =ente_proprietario_new_id
)
select aa.movgest_ts_id from aa where exists (select 1 from bb where bb.movgest_ts_id=aa.movgest_ts_id)          
) as tb        
        )                
                ,
gsa as (select a.movgest_ts_id
    from siac_r_movgest_ts_attr a,
             siac_t_attr b,
             siac_d_ambito c
        where
              a.attr_id = b.attr_id and
              b.attr_code = 'FlagAttivaGsa' and
              c.ente_proprietario_id = b.ente_proprietario_id and
              c.ambito_code = 'AMBITO_GSA' and
              a."boolean" = 'S' and
              now() between a.validita_inizio and COALESCE(a.validita_fine,now())
              and a.data_cancellazione is null
              and b.data_cancellazione is null
              and c.data_cancellazione is null)                
select mod.* from mod join condimp 
on mod.movgest_ts_id=condimp.movgest_ts_id   
join gsa on mod.movgest_ts_id=gsa.movgest_ts_id 
) tb
loop

    if cur_mod_movgest_imp_gsa.tipo_movgest='IT' then --impegno testata
          evento_code_reg_movfin:='MIM-INS-I';
      elsif cur_mod_movgest_imp_gsa.tipo_movgest='IS' then --impegno sub
          evento_code_reg_movfin:='MSI-INS-I';
      end if;
      
      
      INSERT INTO siac.siac_t_reg_movfin
(classif_id_iniziale,classif_id_aggiornato, bil_id, 
validita_inizio,ente_proprietario_id, login_operazione, ambito_id)
values (cur_mod_movgest_imp_gsa.classif_id,cur_mod_movgest_imp_gsa.classif_id,
cur_mod_movgest_imp_gsa.bil_id, valid_inizio,
            ente_proprietario_new_id, login_oper, cur_mod_movgest_imp_gsa.ambito_id)
            returning regmovfin_id
into _regmovfin_id;



INSERT INTO siac.siac_r_reg_movfin_stato
(regmovfin_id,regmovfin_stato_id, validita_inizio, ente_proprietario_id, login_operazione)
select _regmovfin_id,
b.regmovfin_stato_id,
valid_inizio,
ente_proprietario_new_id,
login_oper
from siac_d_reg_movfin_stato b
where b.regmovfin_stato_code = 'N' and
b.ente_proprietario_id = ente_proprietario_new_id
and
now() between b.validita_inizio and COALESCE(b.validita_fine,now());


       
INSERT INTO siac.siac_r_evento_reg_movfin
(regmovfin_id, evento_id,campo_pk_id, validita_inizio, ente_proprietario_id, login_operazione)
select _regmovfin_id,
a.evento_id,
cur_mod_movgest_imp_gsa.mod_id,
valid_inizio,
ente_proprietario_new_id,
login_oper
from siac_d_evento a
where 
a.ente_proprietario_id = ente_proprietario_new_id AND
a.evento_code = evento_code_reg_movfin
and  now() between a.validita_inizio and COALESCE(a.validita_fine,now())
and a.data_cancellazione is null
;
return next;

end loop; --fine impegno GSA mod importo
        _regmovfin_id:=null;


----impegno GSA mod soggetto
for cur_mod_movgest_imp_gsa_sog in
select tb.* from  (
with mod as (
select 
a.mod_id,
c.movgest_ts_id, m.movgest_tipo_code,n.movgest_ts_tipo_code,
 m.movgest_tipo_code||n.movgest_ts_tipo_code tipo_movgest,
o.ambito_id,q.classif_id, l.bil_id
from siac_t_modifica a, 
siac_r_modifica_stato b,
siac_r_movgest_ts_sog_mod c,
siac_t_movgest_ts e, siac_d_modifica_stato f, siac_t_atto_amm g,
siac_r_atto_amm_stato h, siac_d_atto_amm_stato i, 
siac_t_movgest l,
siac_d_movgest_tipo m,siac_d_movgest_ts_tipo n, siac_d_ambito o,
siac_r_movgest_class p, siac_t_class q,siac_d_class_tipo r
where
f.mod_stato_code = 'V' -- la modifica deve essere valida
--and i.attoamm_stato_code = 'DEFINITIVO' -- atto provvisorio
and a.mod_id = b.mod_id
and c.mod_stato_r_id = b.mod_stato_r_id
and e.movgest_ts_id = c.movgest_ts_id
and f.mod_stato_id = b.mod_stato_id
and a.attoamm_id = g.attoamm_id
and g.attoamm_id = h.attoamm_id
and h.attoamm_stato_id = i.attoamm_stato_id
and l.movgest_id=e.movgest_id
and m.movgest_tipo_id=l.movgest_tipo_id
and n.movgest_ts_tipo_id=e.movgest_ts_tipo_id
and a.attoamm_id=attoamm_id_in
and o.ente_proprietario_id=a.ente_proprietario_id
and o.ambito_code='AMBITO_FIN'
and p.movgest_ts_id=e.movgest_ts_id
and q.classif_id=p.classif_id
and r.classif_tipo_id=q.classif_tipo_id
and r.classif_tipo_code like '%PDC%'
and now() between b.validita_inizio and coalesce(b.validita_fine, now())
and now() between h.validita_inizio and coalesce(h.validita_fine, now())
and now() between p.validita_inizio and coalesce(p.validita_fine, now())
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
--and h.data_cancellazione is null
and i.data_cancellazione is null
and l.data_cancellazione is null
and m.data_cancellazione is null
and n.data_cancellazione is null
and o.data_cancellazione is null
and p.data_cancellazione is null
and q.data_cancellazione is null
and r.data_cancellazione is null
)
, /*condimp as (select distinct 
          d.movgest_ts_id
          from 
          siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c,siac_t_movgest_ts d
          where 
          d.movgest_ts_id=a.movgest_ts_id 
          --and  d.movgest_ts_id=cur_mod_movgest.movgest_ts_id
          and a.classif_id=b.classif_id
          and c.classif_tipo_id=b.classif_tipo_id and c.classif_tipo_code like 'PDC%'
          and (b.classif_code like 'U.1.04%' or b.classif_code like 'U.2.03%' or b.classif_code like 'U.2.04%' or 
          b.classif_code like 'U.2.05%' or b.classif_code like 'U.3%' or b.classif_code like 'U.4.01%' or 
          b.classif_code like 'U.4.02%' or b.classif_code like 'U.4.03%' or b.classif_code like 'U.4.04%' or 
          b.classif_code like 'U.5%' or b.classif_code like 'U.7.01%' or b.classif_code like 'U.7.02%')
          and a.data_cancellazione is NULL
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and now() BETWEEN a.validita_inizio and COALESCE(a.validita_fine,now())
          --soggetto collegato
          and ( 
               (    exists (
                             select 1
                             from siac_r_movgest_ts_sog sog
                             where sog.movgest_ts_id = a.movgest_ts_id
                           )
                ) or 
                (    
                    exists (
                             select 1
                             from siac_r_movgest_ts_sogclasse sogcl
                             where  sogcl.movgest_ts_id = a.movgest_ts_id
                    )
                ))    )*/
condimp as (
select tb.movgest_ts_id from (
with aa as (select distinct 
          d.movgest_ts_id
          from 
          siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c,siac_t_movgest_ts d
          where 
          d.movgest_ts_id=a.movgest_ts_id 
          --and  d.movgest_ts_id=cur_mod_movgest.movgest_ts_id
          and a.classif_id=b.classif_id
          and c.classif_tipo_id=b.classif_tipo_id and c.classif_tipo_code like 'PDC%'
          and (b.classif_code like 'U.1.04%' or b.classif_code like 'U.2.03%' or b.classif_code like 'U.2.04%' or 
          b.classif_code like 'U.2.05%' or b.classif_code like 'U.3%' or b.classif_code like 'U.4.01%' or 
          b.classif_code like 'U.4.02%' or b.classif_code like 'U.4.03%' or b.classif_code like 'U.4.04%' or 
          b.classif_code like 'U.5%' or b.classif_code like 'U.7.01%' or b.classif_code like 'U.7.02%')
          and a.data_cancellazione is NULL
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and now() BETWEEN a.validita_inizio and COALESCE(a.validita_fine,now())),
bb as (select movgest_ts_id from siac_r_movgest_ts_sog a
where a.ente_proprietario_id =ente_proprietario_new_id
UNION
select movgest_ts_id from siac_r_movgest_ts_sogclasse b
where b.ente_proprietario_id =ente_proprietario_new_id
)
select aa.movgest_ts_id from aa where exists (select 1 from bb where bb.movgest_ts_id=aa.movgest_ts_id)          
) as tb        
        )                
                ,
gsa as (select a.movgest_ts_id
    from siac_r_movgest_ts_attr a,
             siac_t_attr b,
             siac_d_ambito c
        where
              a.attr_id = b.attr_id and
              b.attr_code = 'FlagAttivaGsa' and
              c.ente_proprietario_id = b.ente_proprietario_id and
              c.ambito_code = 'AMBITO_GSA' and
              a."boolean" = 'S' and
              now() between a.validita_inizio and COALESCE(a.validita_fine,now())
              and a.data_cancellazione is null
              and b.data_cancellazione is null
              and c.data_cancellazione is null)                
select mod.* from mod join condimp 
on mod.movgest_ts_id=condimp.movgest_ts_id   
join gsa on mod.movgest_ts_id=gsa.movgest_ts_id 
) tb 
loop

    if cur_mod_movgest_imp_gsa_sog.tipo_movgest='IT' then --impegno testata
          evento_code_reg_movfin:='MIM-INS-I';
      elsif cur_mod_movgest_imp_gsa_sog.tipo_movgest='IS' then --impegno sub
          evento_code_reg_movfin:='MSI-INS-I';
      end if;
      
      
      INSERT INTO siac.siac_t_reg_movfin
(classif_id_iniziale,classif_id_aggiornato, bil_id, 
validita_inizio,ente_proprietario_id, login_operazione, ambito_id)
values (cur_mod_movgest_imp_gsa_sog.classif_id,cur_mod_movgest_imp_gsa_sog.classif_id,
cur_mod_movgest_imp_gsa_sog.bil_id, valid_inizio,
            ente_proprietario_new_id, login_oper, cur_mod_movgest_imp_gsa_sog.ambito_id)
            returning regmovfin_id
into _regmovfin_id;



INSERT INTO siac.siac_r_reg_movfin_stato
(regmovfin_id,regmovfin_stato_id, validita_inizio, ente_proprietario_id, login_operazione)
select _regmovfin_id,
b.regmovfin_stato_id,
valid_inizio,
ente_proprietario_new_id,
login_oper
from siac_d_reg_movfin_stato b
where b.regmovfin_stato_code = 'N' and
b.ente_proprietario_id = ente_proprietario_new_id
and
now() between b.validita_inizio and COALESCE(b.validita_fine,now());


       
INSERT INTO siac.siac_r_evento_reg_movfin
(regmovfin_id, evento_id,campo_pk_id, validita_inizio, ente_proprietario_id, login_operazione)
select _regmovfin_id,
a.evento_id,
cur_mod_movgest_imp_gsa_sog.mod_id,
valid_inizio,
ente_proprietario_new_id,
login_oper
from siac_d_evento a
where 
a.ente_proprietario_id = ente_proprietario_new_id AND
a.evento_code = evento_code_reg_movfin
and  now() between a.validita_inizio and COALESCE(a.validita_fine,now())
and a.data_cancellazione is null
;
return next;

end loop; --fine impegno GSA mod soggetto
        _regmovfin_id:=null;






--mod accertamento GSA importo
for cur_mod_movgest_acc_gsa in 
select tb.* from (
with mod as (
select 
a.mod_id,
c.movgest_ts_id, m.movgest_tipo_code,n.movgest_ts_tipo_code,
 m.movgest_tipo_code||n.movgest_ts_tipo_code tipo_movgest,
o.ambito_id,q.classif_id, l.bil_id
from siac_t_modifica a, 
siac_r_modifica_stato b,
siac_t_movgest_ts_det_mod c, 
siac_t_movgest_ts e, siac_d_modifica_stato f, siac_t_atto_amm g,
siac_r_atto_amm_stato h, siac_d_atto_amm_stato i, 
siac_t_movgest l,
siac_d_movgest_tipo m,siac_d_movgest_ts_tipo n, siac_d_ambito o,
siac_r_movgest_class p, siac_t_class q,siac_d_class_tipo r
where
f.mod_stato_code = mod_stato_code_in
--and i.attoamm_stato_code = 'DEFINITIVO' -- atto provvisorio
and a.mod_id = b.mod_id
and c.mod_stato_r_id = b.mod_stato_r_id
and e.movgest_ts_id = c.movgest_ts_id
and f.mod_stato_id = b.mod_stato_id
and a.attoamm_id = g.attoamm_id
and g.attoamm_id = h.attoamm_id
and h.attoamm_stato_id = i.attoamm_stato_id
and l.movgest_id=e.movgest_id
and m.movgest_tipo_id=l.movgest_tipo_id
and n.movgest_ts_tipo_id=e.movgest_ts_tipo_id
and a.attoamm_id=attoamm_id_in
and o.ente_proprietario_id=a.ente_proprietario_id
and o.ambito_code='AMBITO_FIN'
and p.movgest_ts_id=e.movgest_ts_id
and q.classif_id=p.classif_id
and r.classif_tipo_id=q.classif_tipo_id
and r.classif_tipo_code like '%PDC%'
and now() between b.validita_inizio and coalesce(b.validita_fine, now())
and now() between h.validita_inizio and coalesce(h.validita_fine, now())
and now() between p.validita_inizio and coalesce(p.validita_fine, now())
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
--and h.data_cancellazione is null
and i.data_cancellazione is null
and l.data_cancellazione is null
and m.data_cancellazione is null
and n.data_cancellazione is null
and o.data_cancellazione is null
and p.data_cancellazione is null
and q.data_cancellazione is null
and r.data_cancellazione is null)
, condacc as (select distinct d.movgest_ts_id
        from siac_r_movgest_class a,
             siac_t_class b,
             siac_d_class_tipo c,
             siac_t_movgest_ts d,
             siac_d_ambito e,
             siac_r_movgest_ts_attr f ,siac_t_attr g
             --,siac_r_movgest_ts_stato h, siac_d_movgest_stato i
        where a.classif_id = b.classif_id and
              b.classif_tipo_id = c.classif_tipo_id and
              c.classif_tipo_code like 'PDC%' and
              d.movgest_ts_id = a.movgest_ts_id and
              --d.movgest_ts_id = cur_mod_movgest.movgest_ts_id and
              e.ente_proprietario_id = b.ente_proprietario_id and
              a.data_cancellazione is null and
              b.data_cancellazione is null and
              c.data_cancellazione is null and
              d.data_cancellazione is null and
              e.data_cancellazione is null and
              e.ambito_code = 'AMBITO_FIN' and 
              now() between a.validita_inizio and COALESCE(a.validita_fine,now()) and 
              f.movgest_ts_id=d.movgest_ts_id and 
              g.attr_id=f.attr_id and 
              g.attr_code='FlagCollegamentoAccertamentoFattura' and 
              f."boolean"='N' and 
              now() between f.validita_inizio and COALESCE(f.validita_fine,now()) and
              --h.movgest_ts_id=d.movgest_ts_id and
              --i.movgest_stato_id=h.movgest_stato_id and 
              --now() between h.validita_inizio and COALESCE(h.validita_fine,now()) and
              --i.movgest_stato_code='D' and
              f.data_cancellazione is null and
              g.data_cancellazione is null 
              --and  h.data_cancellazione is null and
              --i.data_cancellazione is null
              )
,
gsa as (select a.movgest_ts_id
    from siac_r_movgest_ts_attr a,
             siac_t_attr b,
             siac_d_ambito c
        where
              a.attr_id = b.attr_id and
              b.attr_code = 'FlagAttivaGsa' and
              c.ente_proprietario_id = b.ente_proprietario_id and
              c.ambito_code = 'AMBITO_GSA' and
              a."boolean" = 'S' and
              now() between a.validita_inizio and COALESCE(a.validita_fine,now())
              and a.data_cancellazione is null
              and b.data_cancellazione is null
              and c.data_cancellazione is null)                      
select mod.* from mod join condacc
on mod.movgest_ts_id=condacc.movgest_ts_id
join gsa on mod.movgest_ts_id=gsa.movgest_ts_id
) tb
loop

      if cur_mod_movgest_acc_gsa.tipo_movgest='AT' then --accertamento testata
        evento_code_reg_movfin:='MAC-INS-I';
      elsif cur_mod_movgest_acc_gsa.tipo_movgest='AS' then --accertamento sub
        evento_code_reg_movfin:='MSA-INS-I';
      end if;


      INSERT INTO siac.siac_t_reg_movfin
      (classif_id_iniziale,classif_id_aggiornato, bil_id, 
      validita_inizio,ente_proprietario_id, login_operazione, ambito_id)
      values (cur_mod_movgest_acc_gsa.classif_id,cur_mod_movgest_acc_gsa.classif_id,cur_mod_movgest_acc_gsa.bil_id, valid_inizio,
                  ente_proprietario_new_id, login_oper, cur_mod_movgest_acc_gsa.ambito_id)
                  returning regmovfin_id
      into _regmovfin_id;

 
      INSERT INTO siac.siac_r_reg_movfin_stato
      (regmovfin_id,regmovfin_stato_id, validita_inizio, ente_proprietario_id, login_operazione)
      select _regmovfin_id,
      b.regmovfin_stato_id,
      valid_inizio,
      ente_proprietario_new_id,
      login_oper
      from siac_d_reg_movfin_stato b
      where b.regmovfin_stato_code = 'N' and
      b.ente_proprietario_id = ente_proprietario_new_id
      and
      now() between b.validita_inizio and COALESCE(b.validita_fine,now());


                 
      INSERT INTO siac.siac_r_evento_reg_movfin
      (regmovfin_id, evento_id,campo_pk_id, validita_inizio, ente_proprietario_id, login_operazione)
      select _regmovfin_id,
      a.evento_id,
      cur_mod_movgest_acc_gsa.mod_id,
      valid_inizio,
      ente_proprietario_new_id,
      login_oper
      from siac_d_evento a
      where 
      a.ente_proprietario_id = ente_proprietario_new_id AND
      a.evento_code = evento_code_reg_movfin
      and  now() between a.validita_inizio and COALESCE(a.validita_fine,now())
      and a.data_cancellazione is null
      ;

	  return next;

end loop;--fine mod accertamento GSA importo

 
        _regmovfin_id:=null;



--mod accertamento GSA soggetto
for cur_mod_movgest_acc_gsa_sog in 
select tb.* from (
with mod as (
select 
a.mod_id,
c.movgest_ts_id, m.movgest_tipo_code,n.movgest_ts_tipo_code,
 m.movgest_tipo_code||n.movgest_ts_tipo_code tipo_movgest,
o.ambito_id,q.classif_id, l.bil_id
from siac_t_modifica a, 
siac_r_modifica_stato b,
siac_r_movgest_ts_sog_mod c,
siac_t_movgest_ts e, siac_d_modifica_stato f, siac_t_atto_amm g,
siac_r_atto_amm_stato h, siac_d_atto_amm_stato i, 
siac_t_movgest l,
siac_d_movgest_tipo m,siac_d_movgest_ts_tipo n, siac_d_ambito o,
siac_r_movgest_class p, siac_t_class q,siac_d_class_tipo r
where
f.mod_stato_code = 'V' -- la modifica deve essere valida
--and i.attoamm_stato_code = 'DEFINITIVO' -- atto provvisorio
and a.mod_id = b.mod_id
and c.mod_stato_r_id = b.mod_stato_r_id
and e.movgest_ts_id = c.movgest_ts_id
and f.mod_stato_id = b.mod_stato_id
and a.attoamm_id = g.attoamm_id
and g.attoamm_id = h.attoamm_id
and h.attoamm_stato_id = i.attoamm_stato_id
and l.movgest_id=e.movgest_id
and m.movgest_tipo_id=l.movgest_tipo_id
and n.movgest_ts_tipo_id=e.movgest_ts_tipo_id
and a.attoamm_id=attoamm_id_in
and o.ente_proprietario_id=a.ente_proprietario_id
and o.ambito_code='AMBITO_FIN'
and p.movgest_ts_id=e.movgest_ts_id
and q.classif_id=p.classif_id
and r.classif_tipo_id=q.classif_tipo_id
and r.classif_tipo_code like '%PDC%'
and now() between b.validita_inizio and coalesce(b.validita_fine, now())
and now() between h.validita_inizio and coalesce(h.validita_fine, now())
and now() between p.validita_inizio and coalesce(p.validita_fine, now())
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
--and h.data_cancellazione is null
and i.data_cancellazione is null
and l.data_cancellazione is null
and m.data_cancellazione is null
and n.data_cancellazione is null
and o.data_cancellazione is null
and p.data_cancellazione is null
and q.data_cancellazione is null
and r.data_cancellazione is null)
, condacc as (select distinct d.movgest_ts_id
        from siac_r_movgest_class a,
             siac_t_class b,
             siac_d_class_tipo c,
             siac_t_movgest_ts d,
             siac_d_ambito e,
             siac_r_movgest_ts_attr f ,siac_t_attr g
             --,siac_r_movgest_ts_stato h, siac_d_movgest_stato i
        where a.classif_id = b.classif_id and
              b.classif_tipo_id = c.classif_tipo_id and
              c.classif_tipo_code like 'PDC%' and
              d.movgest_ts_id = a.movgest_ts_id and
              --d.movgest_ts_id = cur_mod_movgest.movgest_ts_id and
              e.ente_proprietario_id = b.ente_proprietario_id and
              a.data_cancellazione is null and
              b.data_cancellazione is null and
              c.data_cancellazione is null and
              d.data_cancellazione is null and
              e.data_cancellazione is null and
              e.ambito_code = 'AMBITO_FIN' and 
              now() between a.validita_inizio and COALESCE(a.validita_fine,now()) and 
              f.movgest_ts_id=d.movgest_ts_id and 
              g.attr_id=f.attr_id and 
              g.attr_code='FlagCollegamentoAccertamentoFattura' and 
              f."boolean"='N' and 
              now() between f.validita_inizio and COALESCE(f.validita_fine,now()) and
              --h.movgest_ts_id=d.movgest_ts_id and
              --i.movgest_stato_id=h.movgest_stato_id and 
              --now() between h.validita_inizio and COALESCE(h.validita_fine,now()) and
              --i.movgest_stato_code='D' and
              f.data_cancellazione is null and
              g.data_cancellazione is null 
              --and h.data_cancellazione is null and
              --i.data_cancellazione is null
              )
,
gsa as (select a.movgest_ts_id
    from siac_r_movgest_ts_attr a,
             siac_t_attr b,
             siac_d_ambito c
        where
              a.attr_id = b.attr_id and
              b.attr_code = 'FlagAttivaGsa' and
              c.ente_proprietario_id = b.ente_proprietario_id and
              c.ambito_code = 'AMBITO_GSA' and
              a."boolean" = 'S' and
              now() between a.validita_inizio and COALESCE(a.validita_fine,now())
              and a.data_cancellazione is null
              and b.data_cancellazione is null
              and c.data_cancellazione is null)                      
select mod.* from mod join condacc
on mod.movgest_ts_id=condacc.movgest_ts_id
join gsa on mod.movgest_ts_id=gsa.movgest_ts_id
) tb
loop

      if cur_mod_movgest_acc_gsa_sog.tipo_movgest='AT' then --accertamento testata
        evento_code_reg_movfin:='MAC-INS-I';
      elsif cur_mod_movgest_acc_gsa_sog.tipo_movgest='AS' then --accertamento sub
        evento_code_reg_movfin:='MSA-INS-I';
      end if;


      INSERT INTO siac.siac_t_reg_movfin
      (classif_id_iniziale,classif_id_aggiornato, bil_id, 
      validita_inizio,ente_proprietario_id, login_operazione, ambito_id)
      values (cur_mod_movgest_acc_gsa_sog.classif_id,cur_mod_movgest_acc_gsa_sog.classif_id,
      cur_mod_movgest_acc_gsa_sog.bil_id, valid_inizio,
                  ente_proprietario_new_id, login_oper, cur_mod_movgest_acc_gsa_sog.ambito_id)
                  returning regmovfin_id
      into _regmovfin_id;

    

      INSERT INTO siac.siac_r_reg_movfin_stato
      (regmovfin_id,regmovfin_stato_id, validita_inizio, ente_proprietario_id, login_operazione)
      select _regmovfin_id,
      b.regmovfin_stato_id,
      valid_inizio,
      ente_proprietario_new_id,
      login_oper
      from siac_d_reg_movfin_stato b
      where b.regmovfin_stato_code = 'N' and
      b.ente_proprietario_id = ente_proprietario_new_id
      and
      now() between b.validita_inizio and COALESCE(b.validita_fine,now());


                 
      INSERT INTO siac.siac_r_evento_reg_movfin
      (regmovfin_id, evento_id,campo_pk_id, validita_inizio, ente_proprietario_id, login_operazione)
      select _regmovfin_id,
      a.evento_id,
      cur_mod_movgest_acc_gsa_sog.mod_id,
      valid_inizio,
      ente_proprietario_new_id,
      login_oper
      from siac_d_evento a
      where 
      a.ente_proprietario_id = ente_proprietario_new_id AND
      a.evento_code = evento_code_reg_movfin
      and  now() between a.validita_inizio and COALESCE(a.validita_fine,now())
      and a.data_cancellazione is null
      ;

	  return next;

end loop;--fine mod accertamento GSA soggetto

        _regmovfin_id:=null;























--return;

exception
     when others  THEN
         RAISE EXCEPTION 'Errore DB % %',SQLSTATE,substring(SQLERRM from 1 for 1000);
         _regmovfin_id:=999;
        --esito:='KO';
        --return esito;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;
-- Allineamento function FINE
