/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

-- 23.06.2021 Sofia SIAC-8153 - inizio
select 
fnc_dba_add_column_params('siac_dwh_documento_spesa', 'cod_cdc_sub', 'VARCHAR(200)');
select 
fnc_dba_add_column_params('siac_dwh_documento_spesa', 'desc_cdc_sub', 'VARCHAR(500)');
select 
fnc_dba_add_column_params('siac_dwh_documento_spesa', 'cod_cdr_sub', 'VARCHAR(200)');
select 
fnc_dba_add_column_params('siac_dwh_documento_spesa', 'desc_cdr_sub', 'VARCHAR(500)');
select 
fnc_dba_add_column_params('siac_dwh_st_documento_spesa', 'cod_cdc_sub', 'VARCHAR(200)');
select 
fnc_dba_add_column_params('siac_dwh_st_documento_spesa', 'desc_cdc_sub', 'VARCHAR(500)');
select 
fnc_dba_add_column_params('siac_dwh_st_documento_spesa', 'cod_cdr_sub', 'VARCHAR(200)');
select 
fnc_dba_add_column_params('siac_dwh_st_documento_spesa', 'desc_cdr_sub', 'VARCHAR(500)');


drop FUNCTION if exists siac.fnc_siac_dwh_documento_spesa
(
  p_ente_proprietario_id integer,
  p_data timestamp
);

drop FUNCTION if exists siac.fnc_siac_dwh_st_documento_spesa
(
  p_ente_proprietario_id integer,
  p_data timestamp
);

CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_documento_spesa
(
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
fnc_eseguita integer;

-- 26.01.2021 Sofia Jira SIAC-7518
annoStorico INTEGER:=2018;
caricaDatiStorico integer:=null;
BEGIN

SET local work_mem = '64MB'; -- 22.04.2021 Sofia - indicazioni di Meo B.


select count(*) into fnc_eseguita
from siac_dwh_log_elaborazioni
a where
a.ente_proprietario_id=p_ente_proprietario_id and
a.fnc_elaborazione_inizio >= (now() - interval '13 hours')::timestamp -- non deve esistere  una elaborazione uguale nelle 13 ore che precedono la chimata
and a.fnc_name='fnc_siac_dwh_documento_spesa' ;

-- 13.03.2020 Sofia jira 	SIAC-7513
fnc_eseguita:=0;
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

-- 26.01.2021 Sofia JIRA siac-7518
select substr(liv.gestione_livello_code,1,4)::integer into annoStorico
from siac_d_gestione_livello liv,siac_d_gestione_tipo tipo
where tipo.ente_proprietario_id=p_ente_proprietario_id
and   tipo.gestione_tipo_code='ANNO_STORICO_DWH_DOC_SPESA_ATTIVO'
and   liv.gestione_tipo_id=tipo.gestione_tipo_id
and   tipo.data_cancellazione is null
and   liv.data_cancellazione  is null;

if annoStorico is null then
--	annoStorico:=extract( year from now()::timestamp)-3;
    annoStorico:=2000;
end if;
-- 26.01.2021 Sofia JIRA siac-7518
select fnc_siac_random_user()
into	v_user_table;

-- 26.01.2021 Sofia Jira SIAC-7518
--params := p_ente_proprietario_id::varchar||' - '||p_data::varchar;
-- 26.01.2021 Sofia Jira SIAC-7518
params := p_ente_proprietario_id::varchar||' - annoStorico '||annoStorico::varchar||' - '||p_data::varchar;
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
'fnc_siac_dwh_documento_spesa',
params,
clock_timestamp(),
v_user_table
);


esito:= params||' - Inizio funzione carico documenti spesa (FNC_SIAC_DWH_DOCUMENTO_SPESA) - '||clock_timestamp();
RETURN NEXT;

DELETE FROM siac.siac_dwh_documento_spesa
WHERE ente_proprietario_id = p_ente_proprietario_id;
esito:= 'In funzione carico documenti spesa (FNC_SIAC_DWH_DOCUMENTO_SPESA) - fine eliminazione dati pregressi - '||clock_timestamp();

-- 20.01.2021 Sofia jira SIAC-7967
update siac_dwh_log_elaborazioni   log
set    fnc_elaborazione_fine = clock_timestamp(),
       fnc_durata=clock_timestamp()-log.fnc_elaborazione_inizio,
       fnc_parameters=log.fnc_parameters||' - '||esito
where fnc_user=v_user_table;
RETURN NEXT;


INSERT INTO
  siac.siac_dwh_documento_spesa
(
  ente_proprietario_id,
  ente_denominazione,
  anno_atto_amministrativo,
  num_atto_amministrativo,
  oggetto_atto_amministrativo,
  cod_tipo_atto_amministrativo,
  desc_tipo_atto_amministrativo,
  cod_cdr_atto_amministrativo,
  desc_cdr_atto_amministrativo,
  cod_cdc_atto_amministrativo,
  desc_cdc_atto_amministrativo,
  note_atto_amministrativo,
  cod_stato_atto_amministrativo,
  desc_stato_atto_amministrativo,
  causale_atto_allegato,
  altri_allegati_atto_allegato,
  dati_sensibili_atto_allegato,
  data_scadenza_atto_allegato,
  note_atto_allegato,
  annotazioni_atto_allegato,
  pratica_atto_allegato,
  resp_amm_atto_allegato,
  resp_contabile_atto_allegato,
  anno_titolario_atto_allegato,
  num_titolario_atto_allegato,
  vers_invio_firma_atto_allegato,
  cod_stato_atto_allegato,
  desc_stato_atto_allegato,
  sogg_id_atto_allegato,
  cod_sogg_atto_allegato,
  tipo_sogg_atto_allegato,
  stato_sogg_atto_allegato,
  rag_sociale_sogg_atto_allegato,
  p_iva_sogg_atto_allegato,
  cf_sogg_atto_allegato,
  cf_estero_sogg_atto_allegato,
  nome_sogg_atto_allegato,
  cognome_sogg_atto_allegato,
  anno_doc,
  num_doc,
  desc_doc,
  importo_doc,
  beneficiario_multiplo_doc,
  data_emissione_doc,
  data_scadenza_doc,
  codice_bollo_doc,
  desc_codice_bollo_doc,
  collegato_cec_doc,
  cod_pcc_doc,
  desc_pcc_doc,
  cod_ufficio_doc,
  desc_ufficio_doc,
  cod_stato_doc,
  desc_stato_doc,
  anno_elenco_doc,
  num_elenco_doc,
  data_trasmissione_elenco_doc,
  tot_quote_entrate_elenco_doc,
  tot_quote_spese_elenco_doc,
  tot_da_pagare_elenco_doc,
  tot_da_incassare_elenco_doc,
  cod_stato_elenco_doc,
  desc_stato_elenco_doc,
  cod_gruppo_doc,
  desc_famiglia_doc,
  cod_famiglia_doc,
  desc_gruppo_doc,
  cod_tipo_doc,
  desc_tipo_doc,
  sogg_id_doc,
  cod_sogg_doc,
  tipo_sogg_doc,
  stato_sogg_doc,
  rag_sociale_sogg_doc,
  p_iva_sogg_doc,
  cf_sogg_doc,
  cf_estero_sogg_doc,
  nome_sogg_doc,
  cognome_sogg_doc,
  num_subdoc,
  desc_subdoc,
  importo_subdoc,
  num_reg_iva_subdoc,
  data_scadenza_subdoc,
  convalida_manuale_subdoc,
  importo_da_dedurre_subdoc,
  splitreverse_importo_subdoc,
  pagato_cec_subdoc,
  data_pagamento_cec_subdoc,
  note_tesoriere_subdoc,
  cod_distinta_subdoc,
  desc_distinta_subdoc,
  tipo_commissione_subdoc,
  conto_tesoreria_subdoc,
  rilevante_iva,
  ordinativo_singolo,
  ordinativo_manuale,
  esproprio,
  note,
  cig,
  cup,
  causale_sospensione,
  data_sospensione,
  data_riattivazione,
  causale_ordinativo,
  num_mutuo,
  annotazione,
  certificazione,
  data_certificazione,
  note_certificazione,
  num_certificazione,
  data_scadenza_dopo_sospensione,
  data_esecuzione_pagamento,
  avviso,
  cod_tipo_avviso,
  desc_tipo_avviso,
  sogg_id_subdoc,
  cod_sogg_subdoc,
  tipo_sogg_subdoc,
  stato_sogg_subdoc,
  rag_sociale_sogg_subdoc,
  p_iva_sogg_subdoc,
  cf_sogg_subdoc,
  cf_estero_sogg_subdoc,
  nome_sogg_subdoc,
  cognome_sogg_subdoc,
  sede_secondaria_subdoc,
  bil_anno,
  anno_impegno,
  num_impegno,
  cod_impegno,
  desc_impegno,
  cod_subimpegno,
  desc_subimpegno,
  num_liquidazione,
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
  sogg_id_mod_pag,
  cod_sogg_mod_pag,
  tipo_sogg_mod_pag,
  stato_sogg_mod_pag,
  rag_sociale_sogg_mod_pag,
  p_iva_sogg_mod_pag,
  cf_sogg_mod_pag,
  cf_estero_sogg_mod_pag,
  nome_sogg_mod_pag,
  cognome_sogg_mod_pag,
  anno_liquidazione,
  bil_anno_ord,
  anno_ord,
  num_ord,
  num_subord,
  registro_repertorio,
  anno_repertorio,
  num_repertorio,
  data_repertorio,
  data_ricezione_portale,
  doc_contabilizza_genpcc,
  rudoc_registrazione_anno,
  rudoc_registrazione_numero,
  rudoc_registrazione_data,
  cod_cdc_doc,
  desc_cdc_doc,
  cod_cdr_doc,
  desc_cdr_doc,
  data_operazione_pagamentoincasso,
  pagataincassata,
  note_pagamentoincasso,
  -- 	SIAC-5229
  arrotondamento,
  cod_tipo_splitrev,
  desc_tipo_splitrev,
  stato_liquidazione,
  sdi_lotto_siope_doc,
  cod_siope_tipo_doc,
  desc_siope_tipo_doc,
  desc_siope_tipo_bnkit_doc,
  cod_siope_tipo_analogico_doc,
  desc_siope_tipo_analogico_doc,
  desc_siope_tipo_ana_bnkit_doc,
  cod_siope_tipo_debito_subdoc,
  desc_siope_tipo_debito_subdoc,
  desc_siope_tipo_deb_bnkit_sub,
  cod_siope_ass_motiv_subdoc,
  desc_siope_ass_motiv_subdoc,
  desc_siope_ass_motiv_bnkit_sub,
  cod_siope_scad_motiv_subdoc,
  desc_siope_scad_motiv_subdoc,
  desc_siope_scad_moti_bnkit_sub,
  doc_id, -- SIAC-5573,
  data_ins_atto_allegato,
  data_sosp_atto_allegato,
  causale_sosp_atto_allegato,
  data_riattiva_atto_allegato,
  data_completa_atto_allegato,
  data_convalida_atto_allegato,
  -- SIAC-8153  - Sofia 22.06.2021
  cod_cdc_sub,
  desc_cdc_sub,
  cod_cdr_sub,
  desc_cdr_sub
  -- SIAC-8153  - Sofia 22.06.2021
  
  )
select
tb.v_ente_proprietario_id::INTEGER,
trim(tb.v_ente_denominazione::VARCHAR)::VARCHAR,
trim(tb.v_anno_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_num_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_oggetto_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_cod_tipo_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_desc_tipo_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_cod_cdr_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_desc_cdr_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_cod_cdc_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_desc_cdc_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_note_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_cod_stato_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_desc_stato_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_causale_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_altri_allegati_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_dati_sensibili_atto_allegato::VARCHAR)::VARCHAR,
tb.v_data_scadenza_atto_allegato::timestamp,
trim(tb.v_note_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_annotazioni_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_pratica_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_resp_amm_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_resp_contabile_atto_allegato::VARCHAR)::VARCHAR,
tb.v_anno_titolario_atto_allegato::INTEGER,
trim(tb.v_num_titolario_atto_allegato::VARCHAR)::VARCHAR,
tb.v_vers_invio_firma_atto_allegato::INTEGER,
trim(tb.v_cod_stato_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_desc_stato_atto_allegato::VARCHAR)::VARCHAR,
tb.v_sogg_id_atto_allegato::INTEGER,
trim(tb.v_cod_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_tipo_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_stato_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_rag_sociale_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_p_iva_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_cf_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_cf_estero_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_nome_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_cognome_sogg_atto_allegato::VARCHAR)::VARCHAR,
tb.v_anno_doc::INTEGER,
trim(tb.v_num_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_doc::VARCHAR)::VARCHAR,
tb.v_importo_doc::NUMERIC,
trim(tb.v_beneficiario_multiplo_doc::VARCHAR)::VARCHAR,
tb.v_data_emissione_doc::TIMESTAMP,
tb.v_data_scadenza_doc::TIMESTAMP,
trim(tb.v_codice_bollo_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_codice_bollo_doc::VARCHAR)::VARCHAR,
tb.v_collegato_cec_doc,
trim(tb.v_cod_pcc_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_pcc_doc::VARCHAR)::VARCHAR,
trim(tb.v_cod_ufficio_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_ufficio_doc::VARCHAR)::VARCHAR,
trim(tb.v_cod_stato_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_stato_doc::VARCHAR)::VARCHAR,
tb.v_anno_elenco_doc::INTEGER,
tb.v_num_elenco_doc::INTEGER,
tb.v_data_trasmissione_elenco_doc::TIMESTAMP,
tb.v_tot_quote_entrate_elenco_doc::NUMERIC,
tb.v_tot_quote_spese_elenco_doc::NUMERIC,
tb.v_tot_da_pagare_elenco_doc::NUMERIC,
tb.v_tot_da_incassare_elenco_doc::NUMERIC,
trim(tb.v_cod_stato_elenco_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_stato_elenco_doc::VARCHAR)::VARCHAR,
trim(tb.v_cod_gruppo_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_famiglia_doc::VARCHAR)::VARCHAR,
trim(tb.v_cod_famiglia_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_gruppo_doc::VARCHAR)::VARCHAR,
trim(tb.v_cod_tipo_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_tipo_doc::VARCHAR)::VARCHAR,
tb.v_sogg_id_doc::INTEGER,
trim(tb.v_cod_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_tipo_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_stato_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_rag_sociale_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_p_iva_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_cf_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_cf_estero_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_nome_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_cognome_sogg_doc::VARCHAR)::VARCHAR,
tb.v_num_subdoc::INTEGER,
trim(tb.v_desc_subdoc::VARCHAR)::VARCHAR,
tb.v_importo_subdoc::NUMERIC,
trim(tb.v_num_reg_iva_subdoc::VARCHAR)::VARCHAR,
tb.v_data_scadenza_subdoc::TIMESTAMP,
trim(tb.v_convalida_manuale_subdoc::VARCHAR)::VARCHAR,
tb.v_importo_da_dedurre_subdoc::NUMERIC,
tb.v_splitreverse_importo_subdoc::NUMERIC,
tb.v_pagato_cec_subdoc,
tb.v_data_pagamento_cec_subdoc::TIMESTAMP,
trim(tb.v_note_tesoriere_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_cod_distinta_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_desc_distinta_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_tipo_commissione_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_conto_tesoreria_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_rilevante_iva::VARCHAR)::VARCHAR,
trim(tb.v_ordinativo_singolo::VARCHAR)::VARCHAR,
trim(tb.v_ordinativo_manuale::VARCHAR)::VARCHAR,
trim(tb.v_esproprio::VARCHAR)::VARCHAR,
trim(tb.v_note::VARCHAR)::VARCHAR,
trim(tb.v_cig::VARCHAR)::VARCHAR,
trim(tb.v_cup::VARCHAR)::VARCHAR,
trim(tb.v_causale_sospensione::VARCHAR)::VARCHAR,
trim(tb.v_data_sospensione::VARCHAR)::VARCHAR,
trim(tb.v_data_riattivazione::VARCHAR)::VARCHAR,
trim(tb.v_causale_ordinativo::VARCHAR)::VARCHAR,
tb.v_num_mutuo::INTEGER,
trim(tb.v_annotazione::VARCHAR)::VARCHAR,
trim(tb.v_certificazione::VARCHAR)::VARCHAR,
trim(tb.v_data_certificazione::VARCHAR)::VARCHAR,
trim(tb.v_note_certificazione::VARCHAR)::VARCHAR,
trim(tb.v_num_certificazione::VARCHAR)::VARCHAR,
trim(tb.v_data_scadenza_dopo_sospensione::VARCHAR)::VARCHAR,
trim(tb.v_data_esecuzione_pagamento::VARCHAR)::VARCHAR,
trim(tb.v_avviso::VARCHAR)::VARCHAR,
trim(tb.v_cod_tipo_avviso::VARCHAR)::VARCHAR,
trim(tb.v_desc_tipo_avviso::VARCHAR)::VARCHAR,
tb.v_soggetto_id::INTEGER,
trim(tb.v_cod_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_tipo_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_stato_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_rag_sociale_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_p_iva_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_cf_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_cf_estero_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_nome_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_cognome_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_sede_secondaria_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_bil_anno::VARCHAR)::VARCHAR,
tb.v_anno_impegno::INTEGER,
tb.v_num_impegno::NUMERIC,
trim(tb.v_cod_impegno::VARCHAR)::VARCHAR,
trim(tb.v_desc_impegno::VARCHAR)::VARCHAR,
trim(tb.v_cod_subimpegno::VARCHAR)::VARCHAR,
trim(tb.v_desc_subimpegno::VARCHAR)::VARCHAR,
tb.v_num_liquidazione::NUMERIC,
trim(tb.v_cod_tipo_accredito::VARCHAR)::VARCHAR,
trim(tb.v_desc_tipo_accredito::VARCHAR)::VARCHAR,
tb.v_mod_pag_id::INTEGER,
trim(tb.v_quietanziante::VARCHAR)::VARCHAR,
tb.v_data_nasciata_quietanziante::TIMESTAMP,
trim(tb.v_luogo_nascita_quietanziante::VARCHAR)::VARCHAR,
trim(tb.v_stato_nascita_quietanziante::VARCHAR)::VARCHAR,
trim(tb.v_bic::VARCHAR)::VARCHAR,
trim(tb.v_contocorrente::VARCHAR)::VARCHAR,
trim(tb.v_intestazione_contocorrente::VARCHAR)::VARCHAR,
trim(tb.v_iban::VARCHAR)::VARCHAR,
trim(tb.v_note_mod_pag::VARCHAR)::VARCHAR,
tb.v_data_scadenza_mod_pag::TIMESTAMP,
tb.v_soggetto_id_modpag::INTEGER,
trim(tb.v_cod_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_tipo_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_stato_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_rag_sociale_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_p_iva_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_cf_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_cf_estero_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_nome_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_cognome_sogg_mod_pag::VARCHAR)::VARCHAR,
tb.v_anno_liquidazione::INTEGER,
trim(tb.v_bil_anno_ord::VARCHAR)::VARCHAR,
tb.v_anno_ord::INTEGER,
tb.v_num_ord::NUMERIC,
trim(tb.v_num_subord::VARCHAR)::VARCHAR,
--nuova sezione coge 26-09-2016
trim(tb.v_registro_repertorio::VARCHAR)::VARCHAR,
trim(tb.v_anno_repertorio::VARCHAR)::VARCHAR,
trim(tb.v_num_repertorio::VARCHAR)::VARCHAR,
trim(tb.v_data_repertorio::VARCHAR)::VARCHAR,
trim(tb.v_data_ricezione_portale::VARCHAR)::VARCHAR,
trim(tb.v_doc_contabilizza_genpcc::VARCHAR)::VARCHAR,
-- CR 854
tb.rudoc_registrazione_anno::INTEGER,
tb.rudoc_registrazione_numero::INTEGER,
tb.rudoc_registrazione_data::TIMESTAMP,
trim(tb.cdc_code::VARCHAR)::VARCHAR,
trim(tb.cdc_desc::VARCHAR)::VARCHAR,
trim(tb.cdr_code::VARCHAR)::VARCHAR,
trim(tb.cdr_desc::VARCHAR)::VARCHAR,
trim(tb.v_dataOperazionePagamentoIncasso::VARCHAR)::VARCHAR,
trim(tb.v_flagPagataIncassata::VARCHAR)::VARCHAR,
trim(tb.v_notePagamentoIncasso::VARCHAR)::VARCHAR,
---- SIAC-5229
tb.v_arrotondamento,
-------------
trim(tb.v_cod_tipo_splitrev::VARCHAR)::VARCHAR,
trim(tb.v_desc_tipo_splitrev::VARCHAR)::VARCHAR,
trim(tb.v_liq_stato_desc::VARCHAR)::VARCHAR,
tb.doc_sdi_lotto_siope,
tb.siope_documento_tipo_code,
tb.siope_documento_tipo_desc,
tb.siope_documento_tipo_desc_bnkit,
tb.siope_documento_tipo_analogico_code,
tb.siope_documento_tipo_analogico_desc,
tb.siope_documento_tipo_analogico_desc_bnkit,
tb.siope_tipo_debito_code,
tb.siope_tipo_debito_desc,
tb.siope_tipo_debito_desc_bnkit,
tb.siope_assenza_motivazione_code,
tb.siope_assenza_motivazione_desc,
tb.siope_assenza_motivazione_desc_bnkit,
tb.siope_scadenza_motivo_code,
tb.siope_scadenza_motivo_desc,
tb.siope_scadenza_motivo_desc_bnkit ,
tb.doc_id, -- SIAC-5573,
--- 15.05.2018 Sofia SIAC-6124
tb.data_ins_atto_allegato::timestamp,
tb.data_sosp_atto_allegato::timestamp,
tb.causale_sosp_atto_allegato,
tb.data_riattiva_atto_allegato::timestamp,
tb.data_completa_atto_allegato::timestamp,
tb.data_convalida_atto_allegato::timestamp,
-- SIAC-8153  - Sofia 22.06.2021
tb.cod_cdc_sub,
tb.desc_cdc_sub,
tb.cod_cdr_sub,
tb.desc_cdr_sub
-- SIAC-8153  - Sofia 22.06.2021
from (
with doc as (
  with doc1 as
  (
      with
      doc_totale as
      (
        select distinct
        --h.subdoc_id,a.doc_id,b.doc_tipo_id,c.doc_fam_tipo_id,d.doc_gruppo_tipo_id,e.doc_stato_r_id,f.doc_stato_id,
        b.doc_gruppo_tipo_id,
        g.ente_proprietario_id, g.ente_denominazione,
        a.doc_anno, a.doc_numero, a.doc_desc, a.doc_importo,
        case when a.doc_beneficiariomult= false then 'F' else 'T' end doc_beneficiariomult,
        a.doc_data_emissione, a.doc_data_scadenza,
        case when a.doc_collegato_cec = false then 'F' else 'T' end doc_collegato_cec,
        f.doc_stato_code, f.doc_stato_desc,
        c.doc_fam_tipo_code, c.doc_fam_tipo_desc, b.doc_tipo_code, b.doc_tipo_desc,
        a.doc_id, a.pcccod_id, a.pccuff_id,
        case when a.doc_contabilizza_genpcc= false then 'F' else 'T' end doc_contabilizza_genpcc,
        h.subdoc_numero, h.subdoc_desc, h.subdoc_importo, h.subdoc_nreg_iva, h.subdoc_data_scadenza,
        h.subdoc_convalida_manuale, h.subdoc_importo_da_dedurre, h.subdoc_splitreverse_importo,
        case when h.subdoc_pagato_cec = false then 'F' else 'T' end subdoc_pagato_cec,
        h.subdoc_data_pagamento_cec,
        a.codbollo_id, h.subdoc_id,h.comm_tipo_id,
        h.notetes_id,h.dist_id,h.contotes_id,
        a.doc_sdi_lotto_siope,
        n.siope_documento_tipo_code, n.siope_documento_tipo_desc, n.siope_documento_tipo_desc_bnkit,
        o.siope_documento_tipo_analogico_code, o.siope_documento_tipo_analogico_desc, o.siope_documento_tipo_analogico_desc_bnkit,
        i.siope_tipo_debito_code, i.siope_tipo_debito_desc, i.siope_tipo_debito_desc_bnkit,
        l.siope_assenza_motivazione_code, l.siope_assenza_motivazione_desc, l.siope_assenza_motivazione_desc_bnkit,
        m.siope_scadenza_motivo_code, m.siope_scadenza_motivo_desc, m.siope_scadenza_motivo_desc_bnkit
        from siac_t_doc a
        left join siac_d_siope_documento_tipo n on n.siope_documento_tipo_id = a.siope_documento_tipo_id
                                           and n.data_cancellazione is null
                                           and n.validita_fine is null
        left join siac_d_siope_documento_tipo_analogico o on o.siope_documento_tipo_analogico_id = a.siope_documento_tipo_analogico_id
                                                   and o.data_cancellazione is null
                                                   and o.validita_fine is null
        ,siac_d_doc_tipo b,siac_d_doc_fam_tipo c,
        --siac_d_doc_gruppo d,
        siac_r_doc_stato e,
        siac_d_doc_stato f,
        siac_t_ente_proprietario g,
        siac_t_subdoc h
        left join siac_d_siope_tipo_debito i on i.siope_tipo_debito_id = h.siope_tipo_debito_id
                                           and i.data_cancellazione is null
                                           and i.validita_fine is null
        left join siac_d_siope_assenza_motivazione l on l.siope_assenza_motivazione_id = h.siope_assenza_motivazione_id
                                                   and l.data_cancellazione is null
                                                   and l.validita_fine is null
        left join siac_d_siope_scadenza_motivo m on m.siope_scadenza_motivo_id = h.siope_scadenza_motivo_id
                                                   and m.data_cancellazione is null
                                                   and m.validita_fine is null
        where b.doc_tipo_id=a.doc_tipo_id
        and c.doc_fam_tipo_id=b.doc_fam_tipo_id
        --and b.doc_gruppo_tipo_id=d.doc_gruppo_tipo_id
        and e.doc_id=a.doc_id
        and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
        and f.doc_stato_id=e.doc_stato_id
        and g.ente_proprietario_id=a.ente_proprietario_id
        and g.ente_proprietario_id=p_ente_proprietario_id--p_ente_proprietario_id
        AND c.doc_fam_tipo_code in ('S','IS')
        and h.doc_id=a.doc_id
        -- 22.06.2021 Sofia SIAC-8153
/*        and exists  (select 1 from siac_r_subdoc_class rc,siac_t_class c,siac_d_class_tipo tipo 
             where rc.subdoc_id=h.subdoc_id and  c.classif_id=rc.classif_id and tipo.classif_tipo_id=c.classif_tipo_id and  tipo.classif_tipo_code='CDC'
             and   rc.data_cancellazione is null and rc.validita_fine is null) */
        -- 19.01.2021 Sofia Jira SIAC_7966 - inizio
        -- and date_trunc('DAY',a.data_creazione)=date_trunc('DAY',now())
        -- 26.01.2021 Sofia JIRA SIAC-7518 - inizio
        -- 1 esclusione pagamenti su mandato antecedente annoStorico
        and  not exists
        (
         select 1
         from  siac_t_bil anno,siac_t_periodo per,
               siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo,
               siac_r_ordinativo_stato rs,siac_d_ordinativo_Stato stato,
               siac_t_ordinativo_ts ts,siac_r_subdoc_ordinativo_ts rsub
         where f.doc_stato_code='EM'
         and   rsub.subdoc_id=h.subdoc_id
         and   ts.ord_ts_id=rsub.ord_ts_id
         and   ord.ord_id=ts.ord_id
         and   tipo.ord_tipo_id=ord.ord_tipo_id
         and   tipo.ord_tipo_code='P'
         and   anno.bil_id=ord.bil_id
         and   per.periodo_id=anno.periodo_id
         and   per.anno::integer<=annoStorico
         and   rs.ord_id=ord.ord_id
         and   stato.ord_stato_id=rs.ord_stato_id
         and   stato.ord_stato_code!='A'
         and   not exists
         (
          select 1
          from siac_t_subdoc sub1,siac_r_subdoc_ordinativo_ts rsub1,
               siac_t_ordinativo_ts ts1,siac_t_ordinativo ord1,
               siac_t_bil anno1,siac_t_periodo per1
          where sub1.doc_id=a.doc_id
          and   rsub1.subdoc_id=sub1.subdoc_id
          and   ts1.ord_ts_id=rsub1.ord_ts_id
          and   ord1.ord_id=ts1.ord_id
          and   anno1.bil_id=ord1.bil_id
          and   per1.periodo_id=anno1.bil_id
          and   per1.anno::integer>=annoStorico+1
          and   rsub1.data_cancellazione is null
          and   rsub1.validita_fine is null
         )
         and   rsub.data_cancellazione is null
         and   rsub.validita_fine is null
         and   ts.data_cancellazione is null
         and   ts.validita_fine is null
         and   rs.data_cancellazione is null
         and   rs.validita_fine is null
        )
        -- 2 esclusione pagamenti manuali dataOperazionePagamentoIncasso antecedente annoStorico
        and not exists
        (
          with
          doc_paga_man as
          (
          select rattr.doc_id,
                 substring(coalesce(rattrDataPAga.testo,'01/01/'||(annoStorico+1)::varchar||''),7,4)::integer annoDataPaga
          from siac_r_doc_attr rattr,siac_t_attr attr,
               siac_r_doc_Stato rs,siac_d_doc_Stato stato,
               siac_r_doc_attr rattrDataPaga,siac_t_attr attrDataPaga
          where rattr.doc_id=a.doc_id
          and   attr.attr_id=rattr.attr_id
          and   attr.attr_code='flagPagataIncassata'
          and   rattr.boolean='S'
          and   rs.doc_id=a.doc_id
          and   stato.doc_stato_id=rs.doc_stato_id
          and   stato.doc_stato_code='EM'
          and   rattrDataPaga.doc_id=a.doc_id
          and   attrDataPaga.attr_id=rattrDataPaga.attr_id
          and   attrdatapaga.attr_code='dataOperazionePagamentoIncasso'
          and   rattr.data_cancellazione is null
		  --- SIAC-8239 - Sofia 14.06.21 inizio 
		  and   rattr.validita_fine is null
  	      and   rattrDataPaga.data_cancellazione is null
		  and   rattrDataPaga.validita_fine is null
		  --- SIAC-8239 - Sofia 14.06.21 fine 
          and   rs.data_cancellazione is null
          and   rs.validita_fine is null
          )
          select query_doc_paga_man.*
          from doc_paga_man  query_doc_paga_man
          where query_doc_paga_man.annoDataPaga<=annoStorico
        )
        -- 3 - esclusione documenti ANNULLATI IN ANNI ANTECEDENTI annoStorico
        and not exists
        (
           select 1
           where f.doc_stato_code='A'
           and  extract (year from e.validita_inizio)::integer<=annoStorico
        )
 	    -- 4 - esclusione documenti STORNATI IN ANNI ANTECEDENTI annoStorico
        and not exists
        (
           select 1
           where f.doc_stato_code='ST'
           and  extract (year from e.validita_inizio)::integer<=annoStorico
        )
        -- 19.01.2021 Sofia Jira SIAC_7966 - fine
        -- 26.01.2021 Sofia JIRA SIAC-7518 - fine
        AND a.data_cancellazione IS NULL
        AND b.data_cancellazione IS NULL
        AND c.data_cancellazione IS NULL
        AND e.data_cancellazione IS NULL
        AND f.data_cancellazione IS NULL
        AND g.data_cancellazione IS NULL
        AND h.data_cancellazione IS NULL
  --      order by a.doc_anno::integer desc
     )
     select doc_tot.*
     from doc_totale doc_tot
--     limit 10
)
, docgru as  (
select a.doc_gruppo_tipo_id, a.doc_gruppo_tipo_code, a.doc_gruppo_tipo_desc
 from siac_d_doc_gruppo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null)
select doc1.*, docgru.* from doc1 left join docgru on
docgru.doc_gruppo_tipo_id = doc1.doc_gruppo_tipo_id
  )
  ,bollo as (
  select a.codbollo_id,a.codbollo_code, a.codbollo_desc from siac_d_codicebollo a
  where a.ente_proprietario_id=p_ente_proprietario_id
  and a.data_cancellazione is null)
  ,sogg as (
  with sogg1 as (
  select distinct a.doc_id,b.soggetto_code,
  --d.soggetto_tipo_desc,
  f.soggetto_stato_desc,
  b.partita_iva, b.codice_fiscale, b.codice_fiscale_estero,
   b.soggetto_id
   from
  siac_r_doc_sog a, siac_t_soggetto b ,/*siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d,*/siac_r_soggetto_stato e ,siac_d_soggetto_stato f
  where
  a.ente_proprietario_id=p_ente_proprietario_id
  and a.soggetto_id=b.soggetto_id
 /* and c.soggetto_id=b.soggetto_id
  and d.soggetto_tipo_id=c.soggetto_tipo_id*/
  and e.soggetto_id=b.soggetto_id
  and f.soggetto_stato_id=e.soggetto_stato_id
  /*and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)*/
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
/*  AND c.data_cancellazione IS NULL
  AND d.data_cancellazione IS NULL*/
  AND e.data_cancellazione IS NULL
  AND f.data_cancellazione IS NULL
  --and b.soggetto_id=1862
  ),
  sogg2 as (
  select g.soggetto_id, g.ragione_sociale from  siac_t_persona_giuridica g
  where g.ente_proprietario_id=p_ente_proprietario_id and g.data_cancellazione is null)
  ,sogg3 as (
  select h.soggetto_id,h.nome, h.cognome from siac_t_persona_fisica h
  where h.ente_proprietario_id=p_ente_proprietario_id and h.data_cancellazione is null
  ),
  sogg5 as (select
c.soggetto_id,d.soggetto_tipo_desc
 from siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d where c.ente_proprietario_id=p_ente_proprietario_id and
  d.soggetto_tipo_id=c.soggetto_tipo_id
  and c.data_cancellazione is null
  and d.data_cancellazione is NULL
  AND p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  )
  select sogg1.*, sogg2.ragione_sociale,sogg3.nome, sogg3.cognome, sogg5.soggetto_tipo_desc
  from sogg1 left join sogg2 on sogg1.soggetto_id=sogg2.soggetto_id
  left join sogg3 on sogg1.soggetto_id=sogg3.soggetto_id
  left join sogg5 on sogg1.soggetto_id=sogg5.soggetto_id
  )
  , reguni as (select a.doc_id,a.rudoc_registrazione_anno,
  a.rudoc_registrazione_numero,a.rudoc_registrazione_data
  from siac_t_registrounico_doc a where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  , cdr as (
  select a.doc_id, b.classif_code doc_cdr_cdr_code, b.classif_desc doc_cdr_cdr_desc ,
  null   doc_cdr_cdc_code, null  doc_cdr_cdc_desc
  from siac_r_doc_class a, siac_t_class b, siac_d_class_tipo c
  where a.classif_id=b.classif_id
  and b.classif_tipo_id=c.classif_tipo_id
  and c.classif_tipo_code='CDR'
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  ),
  cdc as (
  select a.doc_id, b.classif_code doc_cdc_cdc_code, b.classif_desc doc_cdc_cdc_desc,
  d.classif_code doc_cdc_cdr_code, d.classif_desc doc_cdc_cdr_desc
  from siac_r_doc_class a, siac_t_class b, siac_d_class_tipo c, siac_t_class d,siac_r_class_fam_tree e
  where a.classif_id=b.classif_id
  and b.classif_tipo_id=c.classif_tipo_id
  and c.classif_tipo_code='CDC'
  and b.classif_id=e.classif_id
  and d.classif_id=e.classif_id_padre
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  AND d.data_cancellazione IS NULL
  AND e.data_cancellazione IS NULL)
  ,pcccod as (select a.pcccod_id,a.pcccod_code,a.pcccod_desc from
  siac_d_pcc_codice  a where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  , pccuff as (
  select a.pccuff_id,a.pccuff_code,a.pccuff_desc from
  siac_d_pcc_ufficio  a where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  , attoamm as (
  with attoamm1 as (
  select
  b.attoamm_id,
  a.subdoc_id,  b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
  d.attoamm_stato_code, d.attoamm_stato_desc,
  e.attoamm_tipo_code, e.attoamm_tipo_desc
  from
  siac_r_subdoc_atto_amm a ,siac_t_atto_amm b ,siac_r_atto_amm_stato c ,siac_d_atto_amm_stato d,
  siac_d_atto_amm_tipo e
  where
  a.ente_proprietario_id=p_ente_proprietario_id and
  a.attoamm_id=b.attoamm_id and c.attoamm_id=b.attoamm_id
  and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  and d.attoamm_stato_id=c.attoamm_stato_id
  and e.attoamm_tipo_id=b.attoamm_tipo_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.data_cancellazione is null
  ),
cdr as (
  select a.attoamm_id, b.classif_code attoamm_cdr_cdr_code, b.classif_desc attoamm_cdr_cdr_desc ,
  null::varchar  attoamm_cdr_cdc_code, null::varchar attoamm_cdr_cdc_desc
  from siac_r_atto_amm_class a, siac_t_class b, siac_d_class_tipo c
  where a.classif_id=b.classif_id
  and b.classif_tipo_id=c.classif_tipo_id
  and c.classif_tipo_code='CDR'
  -- and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data) -- SIAC-5494
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  ),
  cdc as (
  select a.attoamm_id, b.classif_code attoamm_cdc_cdc_code, b.classif_desc attoamm_cdc_cdc_desc,
  d.classif_code attoamm_cdc_cdr_code, d.classif_desc attoamm_cdc_cdr_desc
  from siac_r_atto_amm_class a, siac_t_class b, siac_d_class_tipo c, siac_t_class d,siac_r_class_fam_tree e
  where a.classif_id=b.classif_id
  and b.classif_tipo_id=c.classif_tipo_id
  and c.classif_tipo_code='CDC'
  and b.classif_id=e.classif_id
  and d.classif_id=e.classif_id_padre
  -- and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data) -- SIAC-5494
  -- and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data) -- SIAC-5494
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  AND d.data_cancellazione IS NULL
  AND e.data_cancellazione IS NULL
  )
  select   attoamm1.*,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdc_code::varchar else null::varchar end attoamm_cdc_code,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdc_desc::varchar else null::varchar end attoamm_cdc_desc,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdr_code::varchar else cdr.attoamm_cdr_cdr_code::varchar end attoamm_cdr_code,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdr_desc::varchar else cdr.attoamm_cdr_cdr_desc::varchar end attoamm_cdr_desc
  from attoamm1
  left join cdc on attoamm1.attoamm_id=cdc.attoamm_id
  left join cdr on attoamm1.attoamm_id=cdr.attoamm_id
  ),
  commt as (select a.comm_tipo_id,a.comm_tipo_code,a.comm_tipo_desc
   from siac_d_commissione_tipo a where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  ,
  eldocattall as (
  with eldoc as (
  select a.subdoc_id,a.eldoc_id,
  b.eldoc_anno, b.eldoc_numero, b.eldoc_data_trasmissione, b.eldoc_tot_quoteentrate,
  b.eldoc_tot_quotespese, b.eldoc_tot_dapagare, b.eldoc_tot_daincassare,
  d.eldoc_stato_code, d.eldoc_stato_desc
   from
  siac_r_elenco_doc_subdoc a,siac_t_elenco_doc b, siac_r_elenco_doc_stato c,
  siac_d_elenco_doc_stato d
  where
  a.ente_proprietario_id=p_ente_proprietario_id and
  b.eldoc_id=a.eldoc_id
  and c.eldoc_id=b.eldoc_id
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  and d.eldoc_stato_id=c.eldoc_stato_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  ),
  attoal as (with attoall as (
select distinct
  a.eldoc_id,b.attoal_id,
  b.attoal_causale, b.attoal_altriallegati, b.attoal_dati_sensibili,
         b.attoal_data_scadenza, b.attoal_note, b.attoal_annotazioni, b.attoal_pratica,
         b.attoal_responsabile_amm, b.attoal_responsabile_con, b.attoal_titolario_anno,
         b.attoal_titolario_numero, b.attoal_versione_invio_firma,
         d.attoal_stato_code, d.attoal_stato_desc,
         b.data_creazione data_ins_atto_allegato,   -- 15.05.2018 Sofia siac-6124
	     fnc_siac_attoal_getDataStato(b.attoal_id,'C') data_completa_atto_allegato, -- 22.05.2018 Sofia siac-6124
         fnc_siac_attoal_getDataStato(b.attoal_id,'CV') data_convalida_atto_allegato  -- 22.05.2018 Sofia siac-6124
   from
  siac_r_atto_allegato_elenco_doc a, siac_t_atto_allegato b,
  siac_r_atto_allegato_stato c ,siac_d_atto_allegato_stato d
  where a.ente_proprietario_id=p_ente_proprietario_id and
  a.attoal_id=b.attoal_id
  and c.attoal_id=b.attoal_id
  and d.attoal_stato_id=c.attoal_stato_id
  and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  ),
  soggattoall as (
  with sogg1 as (
  select distinct a.attoal_id,b.soggetto_code soggetto_code_atto_allegato,
  /*d.soggetto_tipo_desc soggetto_tipo_desc_atto_allegato, */
  f.soggetto_stato_desc soggetto_stato_desc_atto_allegato,
  b.partita_iva partita_iva_atto_allegato, b.codice_fiscale codice_fiscale_atto_allegato,
  b.codice_fiscale_estero codice_fiscale_estero_atto_allegato,
  b.soggetto_id soggetto_id_atto_allegato,
  -- 16.05.2018 Sofia siac-6124
  a.attoal_sog_data_sosp data_sosp_atto_allegato,
  a.attoal_sog_causale_sosp causale_sosp_atto_allegato,
  a.attoal_sog_data_riatt data_riattiva_atto_allegato
   from
  siac_r_atto_allegato_sog a, siac_t_soggetto b ,/*siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d,*/siac_r_soggetto_stato e ,siac_d_soggetto_stato f
  where
  a.ente_proprietario_id=p_ente_proprietario_id
  and a.soggetto_id=b.soggetto_id
  /*and c.soggetto_id=b.soggetto_id
  and d.soggetto_tipo_id=c.soggetto_tipo_id*/
  and e.soggetto_id=b.soggetto_id
  and f.soggetto_stato_id=e.soggetto_stato_id
  /*and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)*/
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
/*  AND c.data_cancellazione IS NULL
  AND d.data_cancellazione IS NULL*/
  AND e.data_cancellazione IS NULL
  AND f.data_cancellazione IS NULL
  --and b.soggetto_id=1862
  ),
  sogg2 as (
  select g.soggetto_id, g.ragione_sociale  from  siac_t_persona_giuridica g
  where g.ente_proprietario_id=p_ente_proprietario_id and g.data_cancellazione is null)
  ,sogg3 as (
  select h.soggetto_id,h.nome, h.cognome from siac_t_persona_fisica h
  where h.ente_proprietario_id=p_ente_proprietario_id and h.data_cancellazione is null
  ),
  sogg5 as (select
	c.soggetto_id,d.soggetto_tipo_desc
 from siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d where c.ente_proprietario_id=p_ente_proprietario_id and
  d.soggetto_tipo_id=c.soggetto_tipo_id
  and c.data_cancellazione is null
  and d.data_cancellazione is NULL
  AND p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  )
  select sogg1.*, sogg2.ragione_sociale ragione_sociale_atto_allegato,sogg3.nome nome_atto_allegato,
  sogg3.cognome cognome_atto_allegato, sogg5.soggetto_tipo_desc soggetto_tipo_desc_atto_allegato
  from sogg1 left join sogg2 on sogg1.soggetto_id_atto_allegato=sogg2.soggetto_id
  left join sogg3 on sogg1.soggetto_id_atto_allegato=sogg3.soggetto_id
  left join sogg5 on sogg1.soggetto_id_atto_allegato=sogg5.soggetto_id
  )
  select attoall.*,soggattoall.ragione_sociale_atto_allegato,soggattoall.nome_atto_allegato,
  soggattoall.cognome_atto_allegato,   soggattoall.soggetto_code_atto_allegato,
  soggattoall.soggetto_tipo_desc_atto_allegato,
  soggattoall.soggetto_stato_desc_atto_allegato,
  soggattoall.partita_iva_atto_allegato, soggattoall.codice_fiscale_atto_allegato,
  soggattoall.codice_fiscale_estero_atto_allegato,
  soggattoall.soggetto_id_atto_allegato ,
  -- 16.05.2018 Sofia siac-6124
  soggattoall.data_sosp_atto_allegato,
  soggattoall.causale_sosp_atto_allegato,
  soggattoall.data_riattiva_atto_allegato
  from attoall left join soggattoall
  on attoall.attoal_id=soggattoall.attoal_id
  )
  select distinct eldoc.*,
  attoal.attoal_id,
  attoal.attoal_causale, attoal.attoal_altriallegati, attoal.attoal_dati_sensibili,
         attoal.attoal_data_scadenza, attoal.attoal_note, attoal.attoal_annotazioni, attoal.attoal_pratica,
         attoal.attoal_responsabile_amm, attoal.attoal_responsabile_con, attoal.attoal_titolario_anno,
         attoal.attoal_titolario_numero, attoal.attoal_versione_invio_firma,
         attoal.attoal_stato_code, attoal.attoal_stato_desc,
   attoal.ragione_sociale_atto_allegato,attoal.nome_atto_allegato,attoal.cognome_atto_allegato,
   attoal.soggetto_code_atto_allegato,
  attoal.soggetto_tipo_desc_atto_allegato,
  attoal.soggetto_stato_desc_atto_allegato,
  attoal.partita_iva_atto_allegato, attoal.codice_fiscale_atto_allegato,
  attoal.codice_fiscale_estero_atto_allegato,
  attoal.soggetto_id_atto_allegato,
  -- 15.05.2018 Sofia siac-6124
  attoal.data_ins_atto_allegato,
  attoal.data_sosp_atto_allegato,
  attoal.causale_sosp_atto_allegato,
  attoal.data_riattiva_atto_allegato,
  attoal.data_completa_atto_allegato,
  attoal.data_convalida_atto_allegato
  from eldoc left join attoal
  on eldoc.eldoc_id=attoal.eldoc_id
  ),
  notes as (
  select a.notetes_id,a.notetes_desc from
  siac.siac_d_note_tesoriere a
  where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  , dist as (
  select a.dist_id,a.dist_code, a.dist_desc from siac_d_distinta a
  where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  , contes as (
  select a.contotes_id,a.contotes_desc from siac_d_contotesoreria  a
  where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null),
  split as (select
  a.subdoc_id,b.sriva_tipo_code , b.sriva_tipo_desc from  siac_r_subdoc_splitreverse_iva_tipo a,
  siac_d_splitreverse_iva_tipo b
  where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null
  and b.sriva_tipo_id=a.sriva_tipo_id
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  )
  , liq as (  select  a.subdoc_id,b.liq_anno,b.liq_numero ,d.liq_stato_desc
  from siac.siac_r_subdoc_liquidazione a ,siac_t_liquidazione b,siac_r_liquidazione_stato c ,
  siac_d_liquidazione_stato d
  where a.ente_proprietario_id=p_ente_proprietario_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and b.liq_id=a.liq_id
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  and c.liq_id=b.liq_id
  and d.liq_stato_id=c.liq_stato_id
  --and d.liq_stato_code<>'A'
  and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
),
subcltipoavviso as (select a.subdoc_id,b.classif_code cod_tipo_avviso,b.classif_desc desc_tipo_avviso
 from siac_r_subdoc_class a, siac_t_class b,siac_d_class_tipo c
where a.ente_proprietario_id=p_ente_proprietario_id and b.classif_id=a.classif_id
and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and c.classif_tipo_id=b.classif_tipo_id
and c.classif_tipo_code='TIPO_AVVISO'
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
),
docattr1 as (
SELECT distinct a.doc_id,
a.testo v_registro_repertorio
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'registro_repertorio' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr2 as (
SELECT distinct a.doc_id,
a.numerico v_anno_repertorio
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'anno_repertorio' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr3 as (
SELECT distinct a.doc_id,
a.testo v_num_repertorio
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'num_repertorio' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr4 as (
SELECT distinct a.doc_id,
a.testo v_data_repertorio
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'data_repertorio' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr5 as (
SELECT distinct a.doc_id,
a.testo v_data_ricezione_portale
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'dataRicezionePortale' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr6 as (
SELECT distinct a.doc_id,
a.testo v_dataOperazionePagamentoIncasso
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'dataOperazionePagamentoIncasso' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr7 as (
SELECT distinct a.doc_id,
a."boolean" v_flagPagataIncassata
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagPagataIncassata' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr8 as (
SELECT distinct a.doc_id,
a.testo v_notePagamentoIncasso
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'notePagamentoIncasso' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr9 as (
SELECT distinct a.doc_id,
a.numerico v_arrotondamento
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'arrotondamento' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)

,subdocattr1 as (
SELECT distinct a.subdoc_id,
a."boolean" v_rilevante_iva
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagRilevanteIVA' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr2 as (
SELECT a.subdoc_id, a.subdoc_attr_id,
a."boolean" v_ordinativo_singolo
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagOrdinativoSingolo' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)

,subdocattr3 as (
SELECT distinct a.subdoc_id,
a."boolean" v_esproprio
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagEsproprio' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr4 as (
SELECT distinct a.subdoc_id,
a."boolean" v_certificazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagCertificazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr5 as (
SELECT distinct a.subdoc_id,
a."boolean" v_ordinativo_manuale
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagOrdinativoManuale' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr6 as (
SELECT distinct a.subdoc_id,
a."boolean" v_avviso
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagAvviso' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr7 as (
SELECT distinct a.subdoc_id,
a.numerico v_num_mutuo
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'numeroMutuo' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr8 as (
SELECT distinct a.subdoc_id,
a.testo v_cup
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'cup' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr9 as (
SELECT distinct a.subdoc_id,
a.testo v_cig
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'cig' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr10 as (
SELECT distinct a.subdoc_id,
a.testo v_note_certificazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'noteCertificazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
/* JIRA 5764
,subdocattr11 as (
*/
/*SELECT distinct a.subdoc_id,
a.testo v_data_sospensione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'data_sospensione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)*/
/* JIRA 5764
select a.subdoc_id,to_char(a.subdoc_sosp_data,'dd/mm/yyyy') v_data_sospensione from
siac_t_subdoc_sospensione a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)*/
,subdocattr12 as (
SELECT distinct a.subdoc_id,
a.testo v_data_esecuzione_pagamento
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'dataEsecuzionePagamento' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr13 as (
SELECT distinct a.subdoc_id,
a.testo v_annotazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'annotazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr14 as (
SELECT distinct a.subdoc_id,
a.testo v_num_certificazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'numeroCertificazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr15 as (
SELECT distinct a.subdoc_id,
a.testo v_data_scadenza_dopo_sospensione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'dataScadenzaDopoSospensione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
/* JIRA 5764
,subdocattr16 as (
*/
/*SELECT distinct a.subdoc_id,
a.testo v_data_riattivazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'data_riattivazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)*/
/* JIRA 5764
select a.subdoc_id,to_char(a.subdoc_sosp_data_riattivazione,'dd/mm/yyyy')  v_data_riattivazione
from
siac_t_subdoc_sospensione a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
*/
,subdocattr17 as (
SELECT distinct a.subdoc_id,
a.testo v_causale_ordinativo
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'causaleOrdinativo' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr18 as (
SELECT distinct a.subdoc_id,
a.testo v_note
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'Note' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr19 as (
SELECT distinct a.subdoc_id,
a.testo v_data_certificazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'dataCertificazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
/* JIRA 5764
,subdocattr20 as (*/
/*SELECT distinct a.subdoc_id,
a.testo v_causale_sospensione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'causale_sospensione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)*/
/* JIRA 5764
select
	    a.subdoc_id
		,to_char(a.subdoc_sosp_data,'dd/mm/yyyy') v_data_sospensione
		,to_char(a.subdoc_sosp_data_riattivazione,'dd/mm/yyyy')  v_data_riattivazione
        ,a.subdoc_sosp_causale v_causale_sospensione from
siac_t_subdoc_sospensione a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)*/
,soggsub as (
  with sogg1 as (
  select distinct a.subdoc_id,b.soggetto_code soggetto_code_subdoc,
  f.soggetto_stato_desc soggetto_stato_desc_subdoc,
  b.partita_iva partita_iva_subdoc, b.codice_fiscale codice_fiscale_subdoc,
  b.codice_fiscale_estero codice_fiscale_estero_subdoc,
   b.soggetto_id soggetto_id_subdoc
   from
  siac_r_subdoc_sog a, siac_t_soggetto b ,siac_r_soggetto_stato e ,siac_d_soggetto_stato f
  where
  a.ente_proprietario_id=p_ente_proprietario_id
  and a.soggetto_id=b.soggetto_id
  and e.soggetto_id=b.soggetto_id
  and f.soggetto_stato_id=e.soggetto_stato_id
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
    AND e.data_cancellazione IS NULL
  AND f.data_cancellazione IS NULL
  --and b.soggetto_id=1862
  ),
  sogg2 as (
  select g.soggetto_id, g.ragione_sociale ragione_sociale_subdoc  from  siac_t_persona_giuridica g
  where g.ente_proprietario_id=p_ente_proprietario_id and g.data_cancellazione is null)
  ,sogg3 as (
  select h.soggetto_id,h.nome nome_subdoc, h.cognome cognome_subdoc from siac_t_persona_fisica h
  where h.ente_proprietario_id=p_ente_proprietario_id and h.data_cancellazione is null
  ),
  sogg4 as (
  SELECT a.soggetto_id_da, a.soggetto_id_a
    FROM siac.siac_r_soggetto_relaz a, siac.siac_d_relaz_tipo b
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and
    a.relaz_tipo_id = b.relaz_tipo_id
    AND   b.relaz_tipo_code  = 'SEDE_SECONDARIA'
    AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
    AND   p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
    AND   a.data_cancellazione IS NULL
    AND   b.data_cancellazione IS NULL)
    ,
sogg5 as (select
c.soggetto_id,d.soggetto_tipo_desc soggetto_tipo_desc_subdoc
 from siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d where c.ente_proprietario_id=p_ente_proprietario_id and
  d.soggetto_tipo_id=c.soggetto_tipo_id
  and c.data_cancellazione is null
  and d.data_cancellazione is NULL
  AND p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  )
  select sogg1.*, sogg2.ragione_sociale_subdoc,sogg3.nome_subdoc, sogg3.cognome_subdoc,
  case when sogg4.soggetto_id_da is not null then 'S' else NULL::varchar end v_sede_secondaria_subdoc
  , sogg5.soggetto_tipo_desc_subdoc
  from sogg1 left join sogg2 on sogg1.soggetto_id_subdoc=sogg2.soggetto_id
  left join sogg3 on sogg1.soggetto_id_subdoc=sogg3.soggetto_id
  left join sogg4 on sogg1.soggetto_id_subdoc=sogg4.soggetto_id_a
  left join sogg5 on sogg1.soggetto_id_subdoc=sogg5.soggetto_id
  ),
  imp as (select distinct
  c.movgest_id,b.movgest_ts_id,
a.subdoc_id,
case when g.movgest_ts_tipo_code ='T' then b.movgest_ts_code else NULL::varchar end v_cod_impegno,
case when g.movgest_ts_tipo_code ='T' then c.movgest_desc else NULL::varchar end v_desc_impegno,
case when g.movgest_ts_tipo_code ='S' then b.movgest_ts_code else NULL::varchar end v_cod_subimpegno,
case when g.movgest_ts_tipo_code ='S' then b.movgest_ts_desc else NULL::varchar end v_desc_subimpegno,
e.anno v_bil_anno,
c.movgest_anno v_anno_impegno,
c.movgest_numero v_num_impegno,
g.movgest_ts_tipo_code
from
siac_r_subdoc_movgest_ts a, siac_t_movgest_ts b, siac_t_movgest c, siac_t_bil d,
siac_t_periodo e, siac_d_movgest_tipo f, siac_d_movgest_ts_tipo g
where b.movgest_ts_id=A.movgest_ts_id
and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and c.movgest_id=b.movgest_id
and d.bil_id=c.bil_id
and e.periodo_id=d.periodo_id
and f.movgest_tipo_id=c.movgest_tipo_id
and g.movgest_ts_tipo_id=b.movgest_ts_tipo_id
and f.movgest_tipo_code = 'I'
and a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null),
modpag as (
with modpag0 as (
with modpag1 as (
SELECT
a.subdoc_id,b.quietanziante, b.quietanzante_nascita_data, b.quietanziante_nascita_luogo, b.quietanziante_nascita_stato,
b.bic, b.contocorrente ,b.contocorrente_intestazione,b.iban , b.note , b.data_scadenza,b.accredito_tipo_id,
 b.soggetto_id,a.soggrelmpag_id, b.modpag_id
FROM siac.siac_r_subdoc_modpag a, siac.siac_t_modpag b where
a.ente_proprietario_id=p_ente_proprietario_id and
b.modpag_id = a.modpag_id
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is NULL
and b.data_cancellazione is NULL
)
,actipo as (
select a.accredito_tipo_id,
a.accredito_tipo_code ,
a.accredito_tipo_desc
 from siac.siac_d_accredito_tipo a where a.ente_proprietario_id=p_ente_proprietario_id and
a.data_cancellazione is NULL),
relmodpag as ( SELECT
 a.soggrelmpag_id,
b.soggetto_id_a v_soggetto_id_modpag_cess
 FROM  siac.siac_r_soggrel_modpag a, siac.siac_r_soggetto_relaz b
 WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.soggetto_relaz_id = b.soggetto_relaz_id
 AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
 AND   a.data_cancellazione IS NULL
 AND   p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
 AND   b.data_cancellazione IS NULL
 )
 select
modpag1.subdoc_id,
modpag1.quietanziante v_quietanziante,
modpag1.quietanzante_nascita_data v_data_nasciata_quietanziante,
modpag1.quietanziante_nascita_luogo v_luogo_nascita_quietanziante,
modpag1.quietanziante_nascita_stato v_stato_nascita_quietanziante,
modpag1.bic v_bic, modpag1.contocorrente v_contocorrente,
modpag1.contocorrente_intestazione v_intestazione_contocorrente,
modpag1.iban v_iban, modpag1.note v_note_mod_pag, modpag1.data_scadenza v_data_scadenza_mod_pag,
modpag1.accredito_tipo_id,
 modpag1.soggetto_id v_soggetto_id_modpag_nocess,
modpag1.soggrelmpag_id v_soggrelmpag_id, modpag1.modpag_id v_mod_pag_id,
actipo.accredito_tipo_code v_cod_tipo_accredito,
actipo.accredito_tipo_desc v_desc_tipo_accredito,
case when modpag1.soggrelmpag_id IS NULL THEN modpag1.soggetto_id else relmodpag.v_soggetto_id_modpag_cess
 end v_soggetto_id_modpag
 from modpag1 left join actipo
on modpag1.accredito_tipo_id=actipo.accredito_tipo_id
left join relmodpag on relmodpag.soggrelmpag_id=modpag1.soggrelmpag_id
)
,
 soggmodpag as (
  with sogg1 as (
  select distinct b.soggetto_code, d.soggetto_tipo_desc, f.soggetto_stato_desc,
  b.partita_iva, b.codice_fiscale, b.codice_fiscale_estero,
   b.soggetto_id
   from
  siac_t_soggetto b ,siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d,siac_r_soggetto_stato e ,siac_d_soggetto_stato f
  where
  b.ente_proprietario_id=p_ente_proprietario_id
  and c.soggetto_id=b.soggetto_id
  and d.soggetto_tipo_id=c.soggetto_tipo_id
  and e.soggetto_id=b.soggetto_id
  and f.soggetto_stato_id=e.soggetto_stato_id
  and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  AND d.data_cancellazione IS NULL
  AND e.data_cancellazione IS NULL
  AND f.data_cancellazione IS NULL
  --and b.soggetto_id=1862
  ),
  sogg2 as (
  select g.soggetto_id, g.ragione_sociale from  siac_t_persona_giuridica g
  where g.ente_proprietario_id=p_ente_proprietario_id and g.data_cancellazione is null)
  ,sogg3 as (
  select h.soggetto_id,h.nome, h.cognome from siac_t_persona_fisica h
  where h.ente_proprietario_id=p_ente_proprietario_id and h.data_cancellazione is null
  )
  select sogg1.*, sogg2.ragione_sociale,sogg3.nome, sogg3.cognome
  from sogg1 left join sogg2 on sogg1.soggetto_id=sogg2.soggetto_id
  left join sogg3 on sogg1.soggetto_id=sogg3.soggetto_id
  )
select modpag0.*,soggmodpag.soggetto_code v_cod_sogg_mod_pag, soggmodpag.soggetto_tipo_desc v_tipo_sogg_mod_pag,
soggmodpag.soggetto_stato_desc v_stato_sogg_mod_pag, soggmodpag.ragione_sociale v_rag_sociale_sogg_mod_pag,
soggmodpag.partita_iva v_p_iva_sogg_mod_pag, soggmodpag.codice_fiscale v_cf_sogg_mod_pag,
soggmodpag.codice_fiscale_estero v_cf_estero_sogg_mod_pag,
soggmodpag.nome v_nome_sogg_mod_pag, soggmodpag.cognome v_cognome_sogg_mod_pag
 from modpag0
left join soggmodpag on soggmodpag.soggetto_id=modpag0.v_soggetto_id_modpag
),
ord as (
SELECT
a.subdoc_id,
c.ord_anno, c.ord_numero, b.ord_ts_code, g.anno
    FROM  siac_r_subdoc_ordinativo_ts a, siac_t_ordinativo_ts b, siac_t_ordinativo c,
          siac_r_ordinativo_stato d, siac_d_ordinativo_stato e,
          siac.siac_t_bil f, siac.siac_t_periodo g
    WHERE b.ord_ts_id = a.ord_ts_id
    AND   c.ord_id = b.ord_id
    AND   d.ord_id = c.ord_id
    AND   d.ord_stato_id = e.ord_stato_id
    AND   c.bil_id = f.bil_id
    AND   g.periodo_id = f.periodo_id
    AND   e.ord_stato_code <> 'A'
    AND   a.data_cancellazione IS NULL
    AND   b.data_cancellazione IS NULL
    AND   c.data_cancellazione IS NULL
    AND   d.data_cancellazione IS NULL
    AND   e.data_cancellazione IS NULL
    AND   f.data_cancellazione IS NULL
    AND   g.data_cancellazione IS NULL
    AND   p_data between a.validita_inizio and COALESCE(a.validita_fine,p_data)
    AND   p_data between d.validita_inizio and COALESCE(d.validita_fine,p_data)
    ),
  -- SIAC-8153  - Sofia 22.06.2021
  cdc_subdoc AS
  (
  SELECT c.classif_code cod_cdc_sub,c.classif_desc desc_cdc_sub, rc.subdoc_id
  FROM siac_r_subdoc_class rc,siac_t_class c,siac_d_class_tipo tipo
  WHERE tipo.ente_proprietario_id=p_ente_proprietario_id
  AND   tipo.classif_tipo_code='CDC'
  AND   c.classif_tipo_id=tipo.classif_tipo_id
  AND   rc.classif_id=c.classif_id
  AND   rc.data_cancellazione IS NULL
  AND   p_data between rc.validita_inizio and COALESCE(rc.validita_fine,p_data)
  ),
  cdr_subdoc AS
  (
  SELECT c.classif_code cod_cdr_sub,c.classif_desc desc_cdr_sub, rc.subdoc_id
  FROM siac_r_subdoc_class rc,siac_t_class c,siac_d_class_tipo tipo
  WHERE tipo.ente_proprietario_id=p_ente_proprietario_id
  AND   tipo.classif_tipo_code='CDR'
  AND   c.classif_tipo_id=tipo.classif_tipo_id
  AND   rc.classif_id=c.classif_id
  AND   rc.data_cancellazione IS NULL
  AND   p_data between rc.validita_inizio and COALESCE(rc.validita_fine,p_data)
  )
  -- SIAC-8153  - Sofia 22.06.2021
  select doc.ente_proprietario_id v_ente_proprietario_id,
  doc.ente_denominazione v_ente_denominazione,
  doc.subdoc_id,
  doc.doc_anno v_anno_doc, doc.doc_numero v_num_doc,
  doc.doc_desc v_desc_doc,
  doc.doc_importo v_importo_doc,
  doc.doc_beneficiariomult v_beneficiario_multiplo_doc,
  doc.doc_data_emissione v_data_emissione_doc,
  doc.doc_data_scadenza v_data_scadenza_doc,
  bollo.codbollo_code v_codice_bollo_doc, bollo.codbollo_desc v_desc_codice_bollo_doc,
 doc.doc_collegato_cec v_collegato_cec_doc,
  pcccod.pcccod_code v_cod_pcc_doc,pcccod.pcccod_desc v_desc_pcc_doc
  ,pccuff.pccuff_code v_cod_ufficio_doc,pccuff.pccuff_desc v_desc_ufficio_doc,
  doc.doc_stato_code v_cod_stato_doc, doc.doc_stato_desc v_desc_stato_doc,
   doc.doc_fam_tipo_code v_cod_famiglia_doc, doc.doc_fam_tipo_desc v_desc_famiglia_doc,
doc.doc_tipo_code v_cod_tipo_doc, doc.doc_tipo_desc v_desc_tipo_doc,
doc.subdoc_numero v_num_subdoc, doc.subdoc_desc v_desc_subdoc,doc.subdoc_importo v_importo_subdoc,
doc.subdoc_nreg_iva v_num_reg_iva_subdoc, doc.subdoc_data_scadenza v_data_scadenza_subdoc,
doc.subdoc_convalida_manuale v_convalida_manuale_subdoc, doc.subdoc_importo_da_dedurre v_importo_da_dedurre_subdoc,
doc.subdoc_splitreverse_importo v_splitreverse_importo_subdoc,
doc.subdoc_pagato_cec v_pagato_cec_subdoc,
doc.subdoc_data_pagamento_cec v_data_pagamento_cec_subdoc,
doc.doc_contabilizza_genpcc v_doc_contabilizza_genpcc,
sogg.soggetto_id v_sogg_id_doc,sogg.soggetto_code v_cod_sogg_doc, sogg.soggetto_tipo_desc v_tipo_sogg_doc,
sogg.soggetto_stato_desc v_stato_sogg_doc,sogg.ragione_sociale v_rag_sociale_sogg_doc,
sogg.partita_iva v_p_iva_sogg_doc,
sogg.codice_fiscale v_cf_sogg_doc,
sogg.codice_fiscale_estero v_cf_estero_sogg_doc,
sogg.nome v_nome_sogg_doc, sogg.cognome v_cognome_sogg_doc,
reguni.rudoc_registrazione_anno,reguni.rudoc_registrazione_numero,reguni.rudoc_registrazione_data,
case when cdr.doc_cdr_cdr_code is not null then null::varchar else cdc.doc_cdc_cdc_code::varchar end cdc_code,
case when cdr.doc_cdr_cdr_code is not null then null::varchar else cdc.doc_cdc_cdc_desc::varchar end cdc_desc,
case when cdr.doc_cdr_cdr_code is not null then cdr.doc_cdr_cdr_code::varchar else cdc.doc_cdc_cdr_code::varchar end cdr_code,
-- 13.06.2018 SIAC-6246
-- case when cdr.doc_cdr_cdr_code is not null then cdc.doc_cdc_cdr_code::varchar else cdc.doc_cdc_cdr_desc::varchar end cdr_desc,
-- 13.06.2018 SIAC-6246
case when cdr.doc_cdr_cdr_code is not null then cdr.doc_cdr_cdr_desc::varchar else cdc.doc_cdc_cdr_desc::varchar end cdr_desc,
attoamm.attoamm_anno v_anno_atto_amministrativo, attoamm.attoamm_numero v_num_atto_amministrativo,
attoamm.attoamm_oggetto v_oggetto_atto_amministrativo, attoamm.attoamm_note v_note_atto_amministrativo,
attoamm.attoamm_stato_code v_cod_stato_atto_amministrativo, attoamm.attoamm_stato_desc v_desc_stato_atto_amministrativo,
attoamm.attoamm_tipo_code v_cod_tipo_atto_amministrativo, attoamm.attoamm_tipo_desc v_desc_tipo_atto_amministrativo,
attoamm.attoamm_cdc_code v_cod_cdc_atto_amministrativo,attoamm.attoamm_cdc_desc v_desc_cdc_atto_amministrativo,
attoamm.attoamm_cdr_code v_cod_cdr_atto_amministrativo,attoamm.attoamm_cdr_desc v_desc_cdr_atto_amministrativo,
commt.comm_tipo_code,commt.comm_tipo_desc v_tipo_commissione_subdoc,
eldocattall.subdoc_id,eldocattall.eldoc_id,
eldocattall.eldoc_anno v_anno_elenco_doc,
eldocattall.eldoc_numero v_num_elenco_doc,
eldocattall.eldoc_data_trasmissione v_data_trasmissione_elenco_doc,
eldocattall.eldoc_tot_quoteentrate v_tot_quote_entrate_elenco_doc,
eldocattall.eldoc_tot_quotespese v_tot_quote_spese_elenco_doc,
eldocattall.eldoc_tot_dapagare v_tot_da_pagare_elenco_doc,
eldocattall.eldoc_tot_daincassare v_tot_da_incassare_elenco_doc,
eldocattall.eldoc_stato_code v_cod_stato_elenco_doc,
eldocattall.eldoc_stato_desc v_desc_stato_elenco_doc,
eldocattall.attoal_id,
eldocattall.attoal_causale v_causale_atto_allegato,
eldocattall.attoal_altriallegati v_altri_allegati_atto_allegato, eldocattall.attoal_dati_sensibili v_dati_sensibili_atto_allegato,
eldocattall.attoal_data_scadenza v_data_scadenza_atto_allegato, eldocattall.attoal_note v_note_atto_allegato,
eldocattall.attoal_annotazioni v_annotazioni_atto_allegato, eldocattall.attoal_pratica v_pratica_atto_allegato,
eldocattall.attoal_responsabile_amm v_resp_amm_atto_allegato, eldocattall.attoal_responsabile_con v_resp_contabile_atto_allegato,
eldocattall.attoal_titolario_anno v_anno_titolario_atto_allegato,
eldocattall.attoal_titolario_numero v_num_titolario_atto_allegato, eldocattall.attoal_versione_invio_firma v_vers_invio_firma_atto_allegato,
eldocattall.attoal_stato_code v_cod_stato_atto_allegato, eldocattall.attoal_stato_desc v_desc_stato_atto_allegato,
eldocattall.ragione_sociale_atto_allegato v_rag_sociale_sogg_atto_allegato,
eldocattall.nome_atto_allegato v_nome_sogg_atto_allegato,
eldocattall.cognome_atto_allegato v_cognome_sogg_atto_allegato,
eldocattall.soggetto_code_atto_allegato v_cod_sogg_atto_allegato,
eldocattall.soggetto_tipo_desc_atto_allegato v_tipo_sogg_atto_allegato,
eldocattall.soggetto_stato_desc_atto_allegato v_stato_sogg_atto_allegato,
eldocattall.partita_iva_atto_allegato v_p_iva_sogg_atto_allegato,
eldocattall.codice_fiscale_atto_allegato v_cf_sogg_atto_allegato,
eldocattall.codice_fiscale_estero_atto_allegato v_cf_estero_sogg_atto_allegato,
eldocattall.soggetto_id_atto_allegato v_sogg_id_atto_allegato,
doc.doc_gruppo_tipo_code v_cod_gruppo_doc, doc.doc_gruppo_tipo_desc v_desc_gruppo_doc,
notes.notetes_desc v_note_tesoriere_subdoc,
dist.dist_code v_cod_distinta_subdoc, dist.dist_desc v_desc_distinta_subdoc,
contes.contotes_desc v_conto_tesoreria_subdoc,
split.sriva_tipo_code v_cod_tipo_splitrev , split.sriva_tipo_desc v_desc_tipo_splitrev,
liq.liq_anno v_anno_liquidazione,liq.liq_numero v_num_liquidazione,liq.liq_stato_desc v_liq_stato_desc,
subcltipoavviso.cod_tipo_avviso v_cod_tipo_avviso,subcltipoavviso.desc_tipo_avviso v_desc_tipo_avviso,
docattr1.v_registro_repertorio,
docattr2.v_anno_repertorio,
docattr3.v_num_repertorio,
docattr4.v_data_repertorio,
docattr5.v_data_ricezione_portale,
docattr6.v_dataOperazionePagamentoIncasso,
docattr7.v_flagPagataIncassata,
docattr8.v_notePagamentoIncasso,
-- 	SIAC-5229
docattr9.v_arrotondamento,
--
subdocattr1.v_rilevante_iva,
subdocattr2.v_ordinativo_singolo,
subdocattr3.v_esproprio,
subdocattr4.v_certificazione,
subdocattr5.v_ordinativo_manuale,
subdocattr6.v_avviso,
subdocattr7.v_num_mutuo,
subdocattr8.v_cup,
subdocattr9.v_cig,
subdocattr10.v_note_certificazione,
null::varchar v_data_sospensione, --subdocattr20.v_data_sospensione,--subdocattr11.v_data_sospensione, JIRA 5764
subdocattr12.v_data_esecuzione_pagamento,
subdocattr13.v_annotazione,
subdocattr14.v_num_certificazione,
subdocattr15.v_data_scadenza_dopo_sospensione,
null::varchar v_data_riattivazione,--subdocattr20.v_data_riattivazione,--subdocattr16.v_data_riattivazione, JIRA 5764
subdocattr17.v_causale_ordinativo,
subdocattr18.v_note,
subdocattr19.v_data_certificazione,
null::varchar v_causale_sospensione, --subdocattr20.v_causale_sospensione,JIRA 5764
soggsub.soggetto_code_subdoc v_cod_sogg_subdoc,
soggsub.soggetto_tipo_desc_subdoc v_tipo_sogg_subdoc,
soggsub.soggetto_stato_desc_subdoc v_stato_sogg_subdoc,
soggsub.partita_iva_subdoc v_p_iva_sogg_subdoc,
soggsub.codice_fiscale_subdoc v_cf_sogg_subdoc,
soggsub.codice_fiscale_estero_subdoc v_cf_estero_sogg_subdoc,
soggsub.soggetto_id_subdoc v_soggetto_id,
soggsub.nome_subdoc v_nome_sogg_subdoc,
soggsub.cognome_subdoc v_cognome_sogg_subdoc, soggsub.ragione_sociale_subdoc v_rag_sociale_sogg_subdoc,
soggsub.v_sede_secondaria_subdoc v_sede_secondaria_subdoc,
imp.v_cod_impegno v_cod_impegno,
imp.v_desc_impegno v_desc_impegno,
imp.v_cod_subimpegno v_cod_subimpegno,
imp.v_desc_subimpegno v_desc_subimpegno,
imp.v_bil_anno v_bil_anno,
imp.v_anno_impegno v_anno_impegno,
imp.v_num_impegno v_num_impegno,
imp.movgest_ts_tipo_code,
modpag.v_quietanziante v_quietanziante,
modpag.v_data_nasciata_quietanziante,
modpag.v_luogo_nascita_quietanziante,
modpag.v_stato_nascita_quietanziante,
modpag.v_bic, modpag.v_contocorrente,
modpag.v_intestazione_contocorrente,
modpag.v_iban, modpag.v_note_mod_pag, modpag.v_data_scadenza_mod_pag,
modpag.accredito_tipo_id,
modpag.v_soggetto_id_modpag_nocess,
modpag.v_soggrelmpag_id, modpag.v_mod_pag_id,
modpag.v_cod_tipo_accredito v_cod_tipo_accredito,
modpag.v_desc_tipo_accredito v_desc_tipo_accredito,
modpag.v_soggetto_id_modpag,
modpag.v_cod_sogg_mod_pag, modpag.v_tipo_sogg_mod_pag,
modpag.v_stato_sogg_mod_pag, modpag.v_rag_sociale_sogg_mod_pag,
modpag.v_p_iva_sogg_mod_pag, modpag.v_cf_sogg_mod_pag,
modpag.v_cf_estero_sogg_mod_pag,
modpag.v_nome_sogg_mod_pag, modpag.v_cognome_sogg_mod_pag,
ord.subdoc_id,
ord.ord_anno v_anno_ord, ord.ord_numero v_num_ord, ord.ord_ts_code v_num_subord, ord.anno v_bil_anno_ord,
doc.doc_sdi_lotto_siope,
doc.siope_documento_tipo_code, doc.siope_documento_tipo_desc, doc.siope_documento_tipo_desc_bnkit,
doc.siope_documento_tipo_analogico_code, doc.siope_documento_tipo_analogico_desc, doc.siope_documento_tipo_analogico_desc_bnkit,
doc.siope_tipo_debito_code, doc.siope_tipo_debito_desc, doc.siope_tipo_debito_desc_bnkit,
doc.siope_assenza_motivazione_code, doc.siope_assenza_motivazione_desc, doc.siope_assenza_motivazione_desc_bnkit,
doc.siope_scadenza_motivo_code, doc.siope_scadenza_motivo_desc, doc.siope_scadenza_motivo_desc_bnkit,
doc.doc_id, -- SIAC-5573,
-- 15.05.2018 Sofia siac-6124
eldocattall.data_ins_atto_allegato,
eldocattall.data_sosp_atto_allegato,
eldocattall.causale_sosp_atto_allegato,
eldocattall.data_riattiva_atto_allegato,
eldocattall.data_completa_atto_allegato,
eldocattall.data_convalida_atto_allegato,
-- SIAC-8153 Sofia 22.06.2021
cdc_subdoc.cod_cdc_sub,
cdc_subdoc.desc_cdc_sub,
cdr_subdoc.cod_cdr_sub,
cdr_subdoc.desc_cdr_sub
-- SIAC-8153 Sofia 22.06.2021
from doc
left join bollo on doc.codbollo_id=bollo.codbollo_id
left join sogg on doc.doc_id=sogg.doc_id
left join reguni on doc.doc_id=reguni.doc_id
left join cdc on doc.doc_id=cdc.doc_id
left join cdr on doc.doc_id=cdr.doc_id
left join pcccod on doc.pcccod_id=pcccod.pcccod_id
left join pccuff on doc.pccuff_id=pccuff.pccuff_id
left join attoamm on doc.subdoc_id=attoamm.subdoc_id
left join commt on doc.comm_tipo_id=commt.comm_tipo_id
left join eldocattall on doc.subdoc_id=eldocattall.subdoc_id
left join notes on doc.notetes_id=notes.notetes_id
left join dist  on doc.dist_id=dist.dist_id
left join contes on doc.contotes_id=contes.contotes_id
left join split on doc.subdoc_id=split.subdoc_id
left join liq on doc.subdoc_id=liq.subdoc_id --origina multipli
left join  subcltipoavviso on doc.subdoc_id=subcltipoavviso.subdoc_id
left join docattr1 on doc.doc_id=docattr1.doc_id
left join docattr2 on doc.doc_id=docattr2.doc_id
left join docattr3 on doc.doc_id=docattr3.doc_id
left join docattr4 on doc.doc_id=docattr4.doc_id
left join docattr5 on doc.doc_id=docattr5.doc_id
left join docattr6 on doc.doc_id=docattr6.doc_id
left join docattr7 on doc.doc_id=docattr7.doc_id
left join docattr8 on doc.doc_id=docattr8.doc_id
left join docattr9 on doc.doc_id=docattr9.doc_id
left join subdocattr1 on doc.subdoc_id=subdocattr1.subdoc_id
left join subdocattr2 on doc.subdoc_id=subdocattr2.subdoc_id
left join subdocattr3 on doc.subdoc_id=subdocattr3.subdoc_id
left join subdocattr4 on doc.subdoc_id=subdocattr4.subdoc_id
left join subdocattr5 on doc.subdoc_id=subdocattr5.subdoc_id
left join subdocattr6 on doc.subdoc_id=subdocattr6.subdoc_id
left join subdocattr7 on doc.subdoc_id=subdocattr7.subdoc_id
left join subdocattr8 on doc.subdoc_id=subdocattr8.subdoc_id
left join subdocattr9 on doc.subdoc_id=subdocattr9.subdoc_id
left join subdocattr10 on doc.subdoc_id=subdocattr10.subdoc_id
--left join subdocattr11 on doc.subdoc_id=subdocattr11.subdoc_id
left join subdocattr12 on doc.subdoc_id=subdocattr12.subdoc_id
left join subdocattr13 on doc.subdoc_id=subdocattr13.subdoc_id
left join subdocattr14 on doc.subdoc_id=subdocattr14.subdoc_id
left join subdocattr15 on doc.subdoc_id=subdocattr15.subdoc_id
--left join subdocattr16 on doc.subdoc_id=subdocattr16.subdoc_id
left join subdocattr17 on doc.subdoc_id=subdocattr17.subdoc_id
left join subdocattr18 on doc.subdoc_id=subdocattr18.subdoc_id
left join subdocattr19 on doc.subdoc_id=subdocattr19.subdoc_id
--left join subdocattr20 on doc.subdoc_id=subdocattr20.subdoc_id jira 5764
left join soggsub on soggsub.subdoc_id = doc.subdoc_id
left join imp on imp.subdoc_id=doc.subdoc_id
left join modpag on modpag.subdoc_id=doc.subdoc_id
left join ord on ord.subdoc_id = doc.subdoc_id
-- SIAC-8153 Sofia 22.06.2021
LEFT JOIN cdc_subdoc ON cdc_subdoc.subdoc_id=doc.subdoc_id
LEFT JOIN cdr_subdoc ON cdr_subdoc.subdoc_id=doc.subdoc_id
-- SIAC-8153 Sofia 22.06.2021
) as tb;


esito:= 'In funzione carico documenti spesa (FNC_SIAC_DWH_DOCUMENTO_SPESA) - fine dati variabili - '||clock_timestamp();
RETURN NEXT;

-- 20.01.2021 Sofia jira SIAC-7967
update siac_dwh_log_elaborazioni   log
set    fnc_elaborazione_fine = clock_timestamp(),
       fnc_durata=clock_timestamp()-log.fnc_elaborazione_inizio,
       fnc_parameters=log.fnc_parameters||' - '||esito
where fnc_user=v_user_table;
/*update siac_dwh_log_elaborazioni  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp()-fnc_elaborazione_inizio
where fnc_user=v_user_table;*/

-- 26.01.2021 Sofia JIRA siac-7518
select 1 into caricaDatiStorico
from siac_d_gestione_livello liv,siac_d_gestione_tipo tipo
where tipo.ente_proprietario_id=p_ente_proprietario_id
and   tipo.gestione_tipo_code='CARICA_STORICO_DWH_DOC_SPESA_ATTIVO'
and   liv.gestione_tipo_id=tipo.gestione_tipo_id
and   tipo.data_cancellazione is null
and   liv.data_cancellazione  is null;

-- 26.01.2021 Sofia Jira SIAC-7518
if caricaDatiStorico is not null then

  -- 20.01.2021 Sofia jira SIAC-7967 - inizio
  INSERT INTO siac.siac_dwh_documento_spesa
  (
    ente_proprietario_id,
    ente_denominazione,
    anno_atto_amministrativo,
    num_atto_amministrativo,
    oggetto_atto_amministrativo,
    cod_tipo_atto_amministrativo,
    desc_tipo_atto_amministrativo,
    cod_cdr_atto_amministrativo,
    desc_cdr_atto_amministrativo,
    cod_cdc_atto_amministrativo,
    desc_cdc_atto_amministrativo,
    note_atto_amministrativo,
    cod_stato_atto_amministrativo,
    desc_stato_atto_amministrativo,
    causale_atto_allegato,
    altri_allegati_atto_allegato,
    dati_sensibili_atto_allegato,
    data_scadenza_atto_allegato,
    note_atto_allegato,
    annotazioni_atto_allegato,
    pratica_atto_allegato,
    resp_amm_atto_allegato,
    resp_contabile_atto_allegato,
    anno_titolario_atto_allegato,
    num_titolario_atto_allegato,
    vers_invio_firma_atto_allegato,
    cod_stato_atto_allegato,
    desc_stato_atto_allegato,
    sogg_id_atto_allegato,
    cod_sogg_atto_allegato,
    tipo_sogg_atto_allegato,
    stato_sogg_atto_allegato,
    rag_sociale_sogg_atto_allegato,
    p_iva_sogg_atto_allegato,
    cf_sogg_atto_allegato,
    cf_estero_sogg_atto_allegato,
    nome_sogg_atto_allegato,
    cognome_sogg_atto_allegato,
    anno_doc,
    num_doc,
    desc_doc,
    importo_doc,
    beneficiario_multiplo_doc,
    data_emissione_doc,
    data_scadenza_doc,
    codice_bollo_doc,
    desc_codice_bollo_doc,
    collegato_cec_doc,
    cod_pcc_doc,
    desc_pcc_doc,
    cod_ufficio_doc,
    desc_ufficio_doc,
    cod_stato_doc,
    desc_stato_doc,
    anno_elenco_doc,
    num_elenco_doc,
    data_trasmissione_elenco_doc,
    tot_quote_entrate_elenco_doc,
    tot_quote_spese_elenco_doc,
    tot_da_pagare_elenco_doc,
    tot_da_incassare_elenco_doc,
    cod_stato_elenco_doc,
    desc_stato_elenco_doc,
    cod_gruppo_doc,
    desc_famiglia_doc,
    cod_famiglia_doc,
    desc_gruppo_doc,
    cod_tipo_doc,
    desc_tipo_doc,
    sogg_id_doc,
    cod_sogg_doc,
    tipo_sogg_doc,
    stato_sogg_doc,
    rag_sociale_sogg_doc,
    p_iva_sogg_doc,
    cf_sogg_doc,
    cf_estero_sogg_doc,
    nome_sogg_doc,
    cognome_sogg_doc,
    num_subdoc,
    desc_subdoc,
    importo_subdoc,
    num_reg_iva_subdoc,
    data_scadenza_subdoc,
    convalida_manuale_subdoc,
    importo_da_dedurre_subdoc,
    splitreverse_importo_subdoc,
    pagato_cec_subdoc,
    data_pagamento_cec_subdoc,
    note_tesoriere_subdoc,
    cod_distinta_subdoc,
    desc_distinta_subdoc,
    tipo_commissione_subdoc,
    conto_tesoreria_subdoc,
    rilevante_iva,
    ordinativo_singolo,
    ordinativo_manuale,
    esproprio,
    note,
    cig,
    cup,
    causale_sospensione,
    data_sospensione,
    data_riattivazione,
    causale_ordinativo,
    num_mutuo,
    annotazione,
    certificazione,
    data_certificazione,
    note_certificazione,
    num_certificazione,
    data_scadenza_dopo_sospensione,
    data_esecuzione_pagamento,
    avviso,
    cod_tipo_avviso,
    desc_tipo_avviso,
    sogg_id_subdoc,
    cod_sogg_subdoc,
    tipo_sogg_subdoc,
    stato_sogg_subdoc,
    rag_sociale_sogg_subdoc,
    p_iva_sogg_subdoc,
    cf_sogg_subdoc,
    cf_estero_sogg_subdoc,
    nome_sogg_subdoc,
    cognome_sogg_subdoc,
    sede_secondaria_subdoc,
    bil_anno,
    anno_impegno,
    num_impegno,
    cod_impegno,
    desc_impegno,
    cod_subimpegno,
    desc_subimpegno,
    num_liquidazione,
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
    sogg_id_mod_pag,
    cod_sogg_mod_pag,
    tipo_sogg_mod_pag,
    stato_sogg_mod_pag,
    rag_sociale_sogg_mod_pag,
    p_iva_sogg_mod_pag,
    cf_sogg_mod_pag,
    cf_estero_sogg_mod_pag,
    nome_sogg_mod_pag,
    cognome_sogg_mod_pag,
    anno_liquidazione,
    bil_anno_ord,
    anno_ord,
    num_ord,
    num_subord,
    registro_repertorio,
    anno_repertorio,
    num_repertorio,
    data_repertorio,
    data_ricezione_portale,
    doc_contabilizza_genpcc,
    rudoc_registrazione_anno,
    rudoc_registrazione_numero,
    rudoc_registrazione_data,
    cod_cdc_doc,
    desc_cdc_doc,
    cod_cdr_doc,
    desc_cdr_doc,
    data_operazione_pagamentoincasso,
    pagataincassata,
    note_pagamentoincasso,
    arrotondamento,
    cod_tipo_splitrev,
    desc_tipo_splitrev,
    stato_liquidazione,
    sdi_lotto_siope_doc,
    cod_siope_tipo_doc,
    desc_siope_tipo_doc,
    desc_siope_tipo_bnkit_doc,
    cod_siope_tipo_analogico_doc,
    desc_siope_tipo_analogico_doc,
    desc_siope_tipo_ana_bnkit_doc,
    cod_siope_tipo_debito_subdoc,
    desc_siope_tipo_debito_subdoc,
    desc_siope_tipo_deb_bnkit_sub,
    cod_siope_ass_motiv_subdoc,
    desc_siope_ass_motiv_subdoc,
    desc_siope_ass_motiv_bnkit_sub,
    cod_siope_scad_motiv_subdoc,
    desc_siope_scad_motiv_subdoc,
    desc_siope_scad_moti_bnkit_sub,
    doc_id,
    data_ins_atto_allegato,
    data_sosp_atto_allegato,
    causale_sosp_atto_allegato,
    data_riattiva_atto_allegato,
    data_completa_atto_allegato,
    data_convalida_atto_allegato,
    -- SIAC-8153 Sofia 22.06.2021
    cod_cdc_sub,
    desc_cdc_sub,
    cod_cdr_sub,
    desc_cdr_sub
    -- SIAC-8153 Sofia 22.06.2021
    )
  select
    dw.ente_proprietario_id,
    dw.ente_denominazione,
    dw.anno_atto_amministrativo,
    dw.num_atto_amministrativo,
    dw.oggetto_atto_amministrativo,
    dw.cod_tipo_atto_amministrativo,
    dw.desc_tipo_atto_amministrativo,
    dw.cod_cdr_atto_amministrativo,
    dw.desc_cdr_atto_amministrativo,
    dw.cod_cdc_atto_amministrativo,
    dw.desc_cdc_atto_amministrativo,
    dw.note_atto_amministrativo,
    dw.cod_stato_atto_amministrativo,
    dw.desc_stato_atto_amministrativo,
    dw.causale_atto_allegato,
    dw.altri_allegati_atto_allegato,
    dw.dati_sensibili_atto_allegato,
    dw.data_scadenza_atto_allegato,
    dw.note_atto_allegato,
    dw.annotazioni_atto_allegato,
    dw.pratica_atto_allegato,
    dw.resp_amm_atto_allegato,
    dw.resp_contabile_atto_allegato,
    dw.anno_titolario_atto_allegato,
    dw.num_titolario_atto_allegato,
    dw.vers_invio_firma_atto_allegato,
    dw.cod_stato_atto_allegato,
    dw.desc_stato_atto_allegato,
    dw.sogg_id_atto_allegato,
    dw.cod_sogg_atto_allegato,
    dw.tipo_sogg_atto_allegato,
    dw.stato_sogg_atto_allegato,
    dw.rag_sociale_sogg_atto_allegato,
    dw.p_iva_sogg_atto_allegato,
    dw.cf_sogg_atto_allegato,
    dw.cf_estero_sogg_atto_allegato,
    dw.nome_sogg_atto_allegato,
    dw.cognome_sogg_atto_allegato,
    dw.anno_doc,
    dw.num_doc,
    dw.desc_doc,
    dw.importo_doc,
    dw.beneficiario_multiplo_doc,
    dw.data_emissione_doc,
    dw.data_scadenza_doc,
    dw.codice_bollo_doc,
    dw.desc_codice_bollo_doc,
    dw.collegato_cec_doc,
    dw.cod_pcc_doc,
    dw.desc_pcc_doc,
    dw.cod_ufficio_doc,
    dw.desc_ufficio_doc,
    dw.cod_stato_doc,
    dw.desc_stato_doc,
    dw.anno_elenco_doc,
    dw.num_elenco_doc,
    dw.data_trasmissione_elenco_doc,
    dw.tot_quote_entrate_elenco_doc,
    dw.tot_quote_spese_elenco_doc,
    dw.tot_da_pagare_elenco_doc,
    dw.tot_da_incassare_elenco_doc,
    dw.cod_stato_elenco_doc,
    dw.desc_stato_elenco_doc,
    dw.cod_gruppo_doc,
    dw.desc_famiglia_doc,
    dw.cod_famiglia_doc,
    dw.desc_gruppo_doc,
    dw.cod_tipo_doc,
    dw.desc_tipo_doc,
    dw.sogg_id_doc,
    dw.cod_sogg_doc,
    dw.tipo_sogg_doc,
    dw.stato_sogg_doc,
    dw.rag_sociale_sogg_doc,
    dw.p_iva_sogg_doc,
    dw.cf_sogg_doc,
    dw.cf_estero_sogg_doc,
    dw.nome_sogg_doc,
    dw.cognome_sogg_doc,
    dw.num_subdoc,
    dw.desc_subdoc,
    dw.importo_subdoc,
    dw.num_reg_iva_subdoc,
    dw.data_scadenza_subdoc,
    dw.convalida_manuale_subdoc,
    dw.importo_da_dedurre_subdoc,
    dw.splitreverse_importo_subdoc,
    dw.pagato_cec_subdoc,
    dw.data_pagamento_cec_subdoc,
    dw.note_tesoriere_subdoc,
    dw.cod_distinta_subdoc,
    dw.desc_distinta_subdoc,
    dw.tipo_commissione_subdoc,
    dw.conto_tesoreria_subdoc,
    dw.rilevante_iva,
    dw.ordinativo_singolo,
    dw.ordinativo_manuale,
    dw.esproprio,
    dw.note,
    dw.cig,
    dw.cup,
    dw.causale_sospensione,
    dw.data_sospensione,
    dw.data_riattivazione,
    dw.causale_ordinativo,
    dw.num_mutuo,
    dw.annotazione,
    dw.certificazione,
    dw.data_certificazione,
    dw.note_certificazione,
    dw.num_certificazione,
    dw.data_scadenza_dopo_sospensione,
    dw.data_esecuzione_pagamento,
    dw.avviso,
    dw.cod_tipo_avviso,
    dw.desc_tipo_avviso,
    dw.sogg_id_subdoc,
    dw.cod_sogg_subdoc,
    dw.tipo_sogg_subdoc,
    dw.stato_sogg_subdoc,
    dw.rag_sociale_sogg_subdoc,
    dw.p_iva_sogg_subdoc,
    dw.cf_sogg_subdoc,
    dw.cf_estero_sogg_subdoc,
    dw.nome_sogg_subdoc,
    dw.cognome_sogg_subdoc,
    dw.sede_secondaria_subdoc,
    dw.bil_anno,
    dw.anno_impegno,
    dw.num_impegno,
    dw.cod_impegno,
    dw.desc_impegno,
    dw.cod_subimpegno,
    dw.desc_subimpegno,
    dw.num_liquidazione,
    dw.cod_tipo_accredito,
    dw.desc_tipo_accredito,
    dw.mod_pag_id,
    dw.quietanziante,
    dw.data_nascita_quietanziante,
    dw.luogo_nascita_quietanziante,
    dw.stato_nascita_quietanziante,
    dw.bic,
    dw.contocorrente,
    dw.intestazione_contocorrente,
    dw.iban,
    dw.note_mod_pag,
    dw.data_scadenza_mod_pag,
    dw.sogg_id_mod_pag,
    dw.cod_sogg_mod_pag,
    dw.tipo_sogg_mod_pag,
    dw.stato_sogg_mod_pag,
    dw.rag_sociale_sogg_mod_pag,
    dw.p_iva_sogg_mod_pag,
    dw.cf_sogg_mod_pag,
    dw.cf_estero_sogg_mod_pag,
    dw.nome_sogg_mod_pag,
    dw.cognome_sogg_mod_pag,
    dw.anno_liquidazione,
    dw.bil_anno_ord,
    dw.anno_ord,
    dw.num_ord,
    dw.num_subord,
    dw.registro_repertorio,
    dw.anno_repertorio,
    dw.num_repertorio,
    dw.data_repertorio,
    dw.data_ricezione_portale,
    dw.doc_contabilizza_genpcc,
    dw.rudoc_registrazione_anno,
    dw.rudoc_registrazione_numero,
    dw.rudoc_registrazione_data,
    dw.cod_cdc_doc,
    dw.desc_cdc_doc,
    dw.cod_cdr_doc,
    dw.desc_cdr_doc,
    dw.data_operazione_pagamentoincasso,
    dw.pagataincassata,
    dw.note_pagamentoincasso,
    dw.arrotondamento,
    dw.cod_tipo_splitrev,
    dw.desc_tipo_splitrev,
    dw.stato_liquidazione,
    dw.sdi_lotto_siope_doc,
    dw.cod_siope_tipo_doc,
    dw.desc_siope_tipo_doc,
    dw.desc_siope_tipo_bnkit_doc,
    dw.cod_siope_tipo_analogico_doc,
    dw.desc_siope_tipo_analogico_doc,
    dw.desc_siope_tipo_ana_bnkit_doc,
    dw.cod_siope_tipo_debito_subdoc,
    dw.desc_siope_tipo_debito_subdoc,
    dw.desc_siope_tipo_deb_bnkit_sub,
    dw.cod_siope_ass_motiv_subdoc,
    dw.desc_siope_ass_motiv_subdoc,
    dw.desc_siope_ass_motiv_bnkit_sub,
    dw.cod_siope_scad_motiv_subdoc,
    dw.desc_siope_scad_motiv_subdoc,
    dw.desc_siope_scad_moti_bnkit_sub,
    dw.doc_id,
    dw.data_ins_atto_allegato,
    dw.data_sosp_atto_allegato,
    dw.causale_sosp_atto_allegato,
    dw.data_riattiva_atto_allegato,
    dw.data_completa_atto_allegato,
    dw.data_convalida_atto_allegato,
     -- SIAC-8153 Sofia 22.06.2021
    dw.cod_cdc_sub,
    dw.desc_cdc_sub,
    dw.cod_cdr_sub,
    dw.desc_cdr_sub
    -- SIAC-8153 Sofia 22.06.2021
  from siac_dwh_st_documento_spesa dw
  where dw.ente_proprietario_id=p_ente_proprietario_id;
--  limit 100;

  esito:= 'In funzione carico documenti spesa (FNC_SIAC_DWH_DOCUMENTO_SPESA) - fine dati storici - '||clock_timestamp();
  RETURN NEXT;

  update siac_dwh_log_elaborazioni   log
  set    fnc_elaborazione_fine = clock_timestamp(),
         fnc_durata=clock_timestamp()-log.fnc_elaborazione_inizio,
         fnc_parameters=log.fnc_parameters||' - '||esito
  where fnc_user=v_user_table;
  -- 20.01.2021 Sofia jira SIAC-7967 - fine

end if;
-- 26.01.2021 Sofia Jira SIAC-7518

esito:= 'Fine funzione carico documenti spesa (FNC_SIAC_DWH_DOCUMENTO_SPESA) - '||clock_timestamp();
update siac_dwh_log_elaborazioni   log
set    fnc_elaborazione_fine = clock_timestamp(),
       fnc_durata=clock_timestamp()-log.fnc_elaborazione_inizio,
       fnc_parameters=log.fnc_parameters||' - '||esito
where fnc_user=v_user_table;

end if;



EXCEPTION
WHEN others THEN
  esito:='Funzione carico documenti spesa (FNC_SIAC_DWH_DOCUMENTO_SPESA) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_st_documento_spesa (
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

annoStorico INTEGER:=2018;
elaboraStorico integer:=null;

BEGIN

SET local work_mem = '64MB'; -- 22.04.2021 Sofia - indicazioni di Meo B.

IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;

IF p_data IS NULL THEN
   p_data := now();
END IF;


select substr(liv.gestione_livello_code,1,4)::integer into annoStorico
from siac_d_gestione_livello liv,siac_d_gestione_tipo tipo
where tipo.ente_proprietario_id=p_ente_proprietario_id
and   tipo.gestione_tipo_code='ANNO_STORICO_DWH_DOC_SPESA_ATTIVO'
and   liv.gestione_tipo_id=tipo.gestione_tipo_id
and   tipo.data_cancellazione is null
and   liv.data_cancellazione  is null;

if annoStorico is null then
--	annoStorico:=extract( year from now()::timestamp)-3;
    annoStorico:=2000;

end if;

select fnc_siac_random_user()
into	v_user_table;

params := p_ente_proprietario_id::varchar||' - annoStorico '||annoStorico::varchar||' - '||p_data::varchar;


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
'fnc_siac_dwh_st_documento_spesa',
params,
clock_timestamp(),
v_user_table
);


esito:= 'Inizio funzione carico storico documenti spesa (FNC_SIAC_DWH_ST_DOCUMENTO_SPESA) - '||clock_timestamp();
RETURN NEXT;

select 1 into elaboraStorico
from siac_d_gestione_livello liv,siac_d_gestione_tipo tipo
where tipo.ente_proprietario_id=p_ente_proprietario_id
and   tipo.gestione_tipo_code='ELABORA_STORICO_DWH_DOC_SPESA_ATTIVO'
and   liv.gestione_tipo_id=tipo.gestione_tipo_id
and   tipo.data_cancellazione is null
and   liv.data_cancellazione  is null;

if elaboraStorico is null then
  esito:='Fine funzione carico storico documenti spesa (FNC_SIAC_DWH_ST_DOCUMENTO_SPESA) - elaborazione non attiva - '||clock_timestamp();
  update siac_dwh_log_elaborazioni   log
  set    fnc_elaborazione_fine = clock_timestamp(),
         fnc_durata=clock_timestamp()-log.fnc_elaborazione_inizio,
         fnc_parameters=log.fnc_parameters||' - '||esito
  where fnc_user=v_user_table;
  RETURN next;
  return;

end if;

DELETE FROM siac.siac_dwh_st_documento_spesa
WHERE ente_proprietario_id = p_ente_proprietario_id;
esito:= 'In funzione carico storico documenti spesa (FNC_SIAC_DWH_ST_DOCUMENTO_SPESA) - fine eliminazione dati pregressi - '||clock_timestamp();
update siac_dwh_log_elaborazioni   log
set    fnc_elaborazione_fine = clock_timestamp(),
       fnc_durata=clock_timestamp()-log.fnc_elaborazione_inizio,
       fnc_parameters=log.fnc_parameters||' - '||esito
where fnc_user=v_user_table;
RETURN NEXT;


INSERT INTO
  siac.siac_dwh_st_documento_spesa
(
  ente_proprietario_id,
  ente_denominazione,
  anno_atto_amministrativo,
  num_atto_amministrativo,
  oggetto_atto_amministrativo,
  cod_tipo_atto_amministrativo,
  desc_tipo_atto_amministrativo,
  cod_cdr_atto_amministrativo,
  desc_cdr_atto_amministrativo,
  cod_cdc_atto_amministrativo,
  desc_cdc_atto_amministrativo,
  note_atto_amministrativo,
  cod_stato_atto_amministrativo,
  desc_stato_atto_amministrativo,
  causale_atto_allegato,
  altri_allegati_atto_allegato,
  dati_sensibili_atto_allegato,
  data_scadenza_atto_allegato,
  note_atto_allegato,
  annotazioni_atto_allegato,
  pratica_atto_allegato,
  resp_amm_atto_allegato,
  resp_contabile_atto_allegato,
  anno_titolario_atto_allegato,
  num_titolario_atto_allegato,
  vers_invio_firma_atto_allegato,
  cod_stato_atto_allegato,
  desc_stato_atto_allegato,
  sogg_id_atto_allegato,
  cod_sogg_atto_allegato,
  tipo_sogg_atto_allegato,
  stato_sogg_atto_allegato,
  rag_sociale_sogg_atto_allegato,
  p_iva_sogg_atto_allegato,
  cf_sogg_atto_allegato,
  cf_estero_sogg_atto_allegato,
  nome_sogg_atto_allegato,
  cognome_sogg_atto_allegato,
  anno_doc,
  num_doc,
  desc_doc,
  importo_doc,
  beneficiario_multiplo_doc,
  data_emissione_doc,
  data_scadenza_doc,
  codice_bollo_doc,
  desc_codice_bollo_doc,
  collegato_cec_doc,
  cod_pcc_doc,
  desc_pcc_doc,
  cod_ufficio_doc,
  desc_ufficio_doc,
  cod_stato_doc,
  desc_stato_doc,
  anno_elenco_doc,
  num_elenco_doc,
  data_trasmissione_elenco_doc,
  tot_quote_entrate_elenco_doc,
  tot_quote_spese_elenco_doc,
  tot_da_pagare_elenco_doc,
  tot_da_incassare_elenco_doc,
  cod_stato_elenco_doc,
  desc_stato_elenco_doc,
  cod_gruppo_doc,
  desc_famiglia_doc,
  cod_famiglia_doc,
  desc_gruppo_doc,
  cod_tipo_doc,
  desc_tipo_doc,
  sogg_id_doc,
  cod_sogg_doc,
  tipo_sogg_doc,
  stato_sogg_doc,
  rag_sociale_sogg_doc,
  p_iva_sogg_doc,
  cf_sogg_doc,
  cf_estero_sogg_doc,
  nome_sogg_doc,
  cognome_sogg_doc,
  num_subdoc,
  desc_subdoc,
  importo_subdoc,
  num_reg_iva_subdoc,
  data_scadenza_subdoc,
  convalida_manuale_subdoc,
  importo_da_dedurre_subdoc,
  splitreverse_importo_subdoc,
  pagato_cec_subdoc,
  data_pagamento_cec_subdoc,
  note_tesoriere_subdoc,
  cod_distinta_subdoc,
  desc_distinta_subdoc,
  tipo_commissione_subdoc,
  conto_tesoreria_subdoc,
  rilevante_iva,
  ordinativo_singolo,
  ordinativo_manuale,
  esproprio,
  note,
  cig,
  cup,
  causale_sospensione,
  data_sospensione,
  data_riattivazione,
  causale_ordinativo,
  num_mutuo,
  annotazione,
  certificazione,
  data_certificazione,
  note_certificazione,
  num_certificazione,
  data_scadenza_dopo_sospensione,
  data_esecuzione_pagamento,
  avviso,
  cod_tipo_avviso,
  desc_tipo_avviso,
  sogg_id_subdoc,
  cod_sogg_subdoc,
  tipo_sogg_subdoc,
  stato_sogg_subdoc,
  rag_sociale_sogg_subdoc,
  p_iva_sogg_subdoc,
  cf_sogg_subdoc,
  cf_estero_sogg_subdoc,
  nome_sogg_subdoc,
  cognome_sogg_subdoc,
  sede_secondaria_subdoc,
  bil_anno,
  anno_impegno,
  num_impegno,
  cod_impegno,
  desc_impegno,
  cod_subimpegno,
  desc_subimpegno,
  num_liquidazione,
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
  sogg_id_mod_pag,
  cod_sogg_mod_pag,
  tipo_sogg_mod_pag,
  stato_sogg_mod_pag,
  rag_sociale_sogg_mod_pag,
  p_iva_sogg_mod_pag,
  cf_sogg_mod_pag,
  cf_estero_sogg_mod_pag,
  nome_sogg_mod_pag,
  cognome_sogg_mod_pag,
  anno_liquidazione,
  bil_anno_ord,
  anno_ord,
  num_ord,
  num_subord,
  registro_repertorio,
  anno_repertorio,
  num_repertorio,
  data_repertorio,
  data_ricezione_portale,
  doc_contabilizza_genpcc,
  rudoc_registrazione_anno,
  rudoc_registrazione_numero,
  rudoc_registrazione_data,
  cod_cdc_doc,
  desc_cdc_doc,
  cod_cdr_doc,
  desc_cdr_doc,
  data_operazione_pagamentoincasso,
  pagataincassata,
  note_pagamentoincasso,
  arrotondamento,
  cod_tipo_splitrev,
  desc_tipo_splitrev,
  stato_liquidazione,
  sdi_lotto_siope_doc,
  cod_siope_tipo_doc,
  desc_siope_tipo_doc,
  desc_siope_tipo_bnkit_doc,
  cod_siope_tipo_analogico_doc,
  desc_siope_tipo_analogico_doc,
  desc_siope_tipo_ana_bnkit_doc,
  cod_siope_tipo_debito_subdoc,
  desc_siope_tipo_debito_subdoc,
  desc_siope_tipo_deb_bnkit_sub,
  cod_siope_ass_motiv_subdoc,
  desc_siope_ass_motiv_subdoc,
  desc_siope_ass_motiv_bnkit_sub,
  cod_siope_scad_motiv_subdoc,
  desc_siope_scad_motiv_subdoc,
  desc_siope_scad_moti_bnkit_sub,
  doc_id,
  data_ins_atto_allegato,
  data_sosp_atto_allegato,
  causale_sosp_atto_allegato,
  data_riattiva_atto_allegato,
  data_completa_atto_allegato,
  data_convalida_atto_allegato,
  -- SIAC-8153  - Sofia 22.06.2021
  cod_cdc_sub,
  desc_cdc_sub,
  cod_cdr_sub,
  desc_cdr_sub
  -- SIAC-8153  - Sofia 22.06.2021
  )
select
tb.v_ente_proprietario_id::INTEGER,
trim(tb.v_ente_denominazione::VARCHAR)::VARCHAR,
trim(tb.v_anno_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_num_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_oggetto_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_cod_tipo_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_desc_tipo_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_cod_cdr_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_desc_cdr_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_cod_cdc_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_desc_cdc_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_note_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_cod_stato_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_desc_stato_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_causale_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_altri_allegati_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_dati_sensibili_atto_allegato::VARCHAR)::VARCHAR,
tb.v_data_scadenza_atto_allegato::timestamp,
trim(tb.v_note_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_annotazioni_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_pratica_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_resp_amm_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_resp_contabile_atto_allegato::VARCHAR)::VARCHAR,
tb.v_anno_titolario_atto_allegato::INTEGER,
trim(tb.v_num_titolario_atto_allegato::VARCHAR)::VARCHAR,
tb.v_vers_invio_firma_atto_allegato::INTEGER,
trim(tb.v_cod_stato_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_desc_stato_atto_allegato::VARCHAR)::VARCHAR,
tb.v_sogg_id_atto_allegato::INTEGER,
trim(tb.v_cod_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_tipo_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_stato_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_rag_sociale_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_p_iva_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_cf_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_cf_estero_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_nome_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_cognome_sogg_atto_allegato::VARCHAR)::VARCHAR,
tb.v_anno_doc::INTEGER,
trim(tb.v_num_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_doc::VARCHAR)::VARCHAR,
tb.v_importo_doc::NUMERIC,
trim(tb.v_beneficiario_multiplo_doc::VARCHAR)::VARCHAR,
tb.v_data_emissione_doc::TIMESTAMP,
tb.v_data_scadenza_doc::TIMESTAMP,
trim(tb.v_codice_bollo_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_codice_bollo_doc::VARCHAR)::VARCHAR,
tb.v_collegato_cec_doc,
trim(tb.v_cod_pcc_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_pcc_doc::VARCHAR)::VARCHAR,
trim(tb.v_cod_ufficio_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_ufficio_doc::VARCHAR)::VARCHAR,
trim(tb.v_cod_stato_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_stato_doc::VARCHAR)::VARCHAR,
tb.v_anno_elenco_doc::INTEGER,
tb.v_num_elenco_doc::INTEGER,
tb.v_data_trasmissione_elenco_doc::TIMESTAMP,
tb.v_tot_quote_entrate_elenco_doc::NUMERIC,
tb.v_tot_quote_spese_elenco_doc::NUMERIC,
tb.v_tot_da_pagare_elenco_doc::NUMERIC,
tb.v_tot_da_incassare_elenco_doc::NUMERIC,
trim(tb.v_cod_stato_elenco_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_stato_elenco_doc::VARCHAR)::VARCHAR,
trim(tb.v_cod_gruppo_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_famiglia_doc::VARCHAR)::VARCHAR,
trim(tb.v_cod_famiglia_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_gruppo_doc::VARCHAR)::VARCHAR,
trim(tb.v_cod_tipo_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_tipo_doc::VARCHAR)::VARCHAR,
tb.v_sogg_id_doc::INTEGER,
trim(tb.v_cod_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_tipo_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_stato_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_rag_sociale_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_p_iva_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_cf_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_cf_estero_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_nome_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_cognome_sogg_doc::VARCHAR)::VARCHAR,
tb.v_num_subdoc::INTEGER,
trim(tb.v_desc_subdoc::VARCHAR)::VARCHAR,
tb.v_importo_subdoc::NUMERIC,
trim(tb.v_num_reg_iva_subdoc::VARCHAR)::VARCHAR,
tb.v_data_scadenza_subdoc::TIMESTAMP,
trim(tb.v_convalida_manuale_subdoc::VARCHAR)::VARCHAR,
tb.v_importo_da_dedurre_subdoc::NUMERIC,
tb.v_splitreverse_importo_subdoc::NUMERIC,
tb.v_pagato_cec_subdoc,
tb.v_data_pagamento_cec_subdoc::TIMESTAMP,
trim(tb.v_note_tesoriere_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_cod_distinta_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_desc_distinta_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_tipo_commissione_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_conto_tesoreria_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_rilevante_iva::VARCHAR)::VARCHAR,
trim(tb.v_ordinativo_singolo::VARCHAR)::VARCHAR,
trim(tb.v_ordinativo_manuale::VARCHAR)::VARCHAR,
trim(tb.v_esproprio::VARCHAR)::VARCHAR,
trim(tb.v_note::VARCHAR)::VARCHAR,
trim(tb.v_cig::VARCHAR)::VARCHAR,
trim(tb.v_cup::VARCHAR)::VARCHAR,
trim(tb.v_causale_sospensione::VARCHAR)::VARCHAR,
trim(tb.v_data_sospensione::VARCHAR)::VARCHAR,
trim(tb.v_data_riattivazione::VARCHAR)::VARCHAR,
trim(tb.v_causale_ordinativo::VARCHAR)::VARCHAR,
tb.v_num_mutuo::INTEGER,
trim(tb.v_annotazione::VARCHAR)::VARCHAR,
trim(tb.v_certificazione::VARCHAR)::VARCHAR,
trim(tb.v_data_certificazione::VARCHAR)::VARCHAR,
trim(tb.v_note_certificazione::VARCHAR)::VARCHAR,
trim(tb.v_num_certificazione::VARCHAR)::VARCHAR,
trim(tb.v_data_scadenza_dopo_sospensione::VARCHAR)::VARCHAR,
trim(tb.v_data_esecuzione_pagamento::VARCHAR)::VARCHAR,
trim(tb.v_avviso::VARCHAR)::VARCHAR,
trim(tb.v_cod_tipo_avviso::VARCHAR)::VARCHAR,
trim(tb.v_desc_tipo_avviso::VARCHAR)::VARCHAR,
tb.v_soggetto_id::INTEGER,
trim(tb.v_cod_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_tipo_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_stato_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_rag_sociale_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_p_iva_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_cf_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_cf_estero_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_nome_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_cognome_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_sede_secondaria_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_bil_anno::VARCHAR)::VARCHAR,
tb.v_anno_impegno::INTEGER,
tb.v_num_impegno::NUMERIC,
trim(tb.v_cod_impegno::VARCHAR)::VARCHAR,
trim(tb.v_desc_impegno::VARCHAR)::VARCHAR,
trim(tb.v_cod_subimpegno::VARCHAR)::VARCHAR,
trim(tb.v_desc_subimpegno::VARCHAR)::VARCHAR,
tb.v_num_liquidazione::NUMERIC,
trim(tb.v_cod_tipo_accredito::VARCHAR)::VARCHAR,
trim(tb.v_desc_tipo_accredito::VARCHAR)::VARCHAR,
tb.v_mod_pag_id::INTEGER,
trim(tb.v_quietanziante::VARCHAR)::VARCHAR,
tb.v_data_nasciata_quietanziante::TIMESTAMP,
trim(tb.v_luogo_nascita_quietanziante::VARCHAR)::VARCHAR,
trim(tb.v_stato_nascita_quietanziante::VARCHAR)::VARCHAR,
trim(tb.v_bic::VARCHAR)::VARCHAR,
trim(tb.v_contocorrente::VARCHAR)::VARCHAR,
trim(tb.v_intestazione_contocorrente::VARCHAR)::VARCHAR,
trim(tb.v_iban::VARCHAR)::VARCHAR,
trim(tb.v_note_mod_pag::VARCHAR)::VARCHAR,
tb.v_data_scadenza_mod_pag::TIMESTAMP,
tb.v_soggetto_id_modpag::INTEGER,
trim(tb.v_cod_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_tipo_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_stato_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_rag_sociale_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_p_iva_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_cf_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_cf_estero_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_nome_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_cognome_sogg_mod_pag::VARCHAR)::VARCHAR,
tb.v_anno_liquidazione::INTEGER,
trim(tb.v_bil_anno_ord::VARCHAR)::VARCHAR,
tb.v_anno_ord::INTEGER,
tb.v_num_ord::NUMERIC,
trim(tb.v_num_subord::VARCHAR)::VARCHAR,
trim(tb.v_registro_repertorio::VARCHAR)::VARCHAR,
trim(tb.v_anno_repertorio::VARCHAR)::VARCHAR,
trim(tb.v_num_repertorio::VARCHAR)::VARCHAR,
trim(tb.v_data_repertorio::VARCHAR)::VARCHAR,
trim(tb.v_data_ricezione_portale::VARCHAR)::VARCHAR,
trim(tb.v_doc_contabilizza_genpcc::VARCHAR)::VARCHAR,
tb.rudoc_registrazione_anno::INTEGER,
tb.rudoc_registrazione_numero::INTEGER,
tb.rudoc_registrazione_data::TIMESTAMP,
trim(tb.cdc_code::VARCHAR)::VARCHAR,
trim(tb.cdc_desc::VARCHAR)::VARCHAR,
trim(tb.cdr_code::VARCHAR)::VARCHAR,
trim(tb.cdr_desc::VARCHAR)::VARCHAR,
trim(tb.v_dataOperazionePagamentoIncasso::VARCHAR)::VARCHAR,
trim(tb.v_flagPagataIncassata::VARCHAR)::VARCHAR,
trim(tb.v_notePagamentoIncasso::VARCHAR)::VARCHAR,
tb.v_arrotondamento,
trim(tb.v_cod_tipo_splitrev::VARCHAR)::VARCHAR,
trim(tb.v_desc_tipo_splitrev::VARCHAR)::VARCHAR,
trim(tb.v_liq_stato_desc::VARCHAR)::VARCHAR,
tb.doc_sdi_lotto_siope,
tb.siope_documento_tipo_code,
tb.siope_documento_tipo_desc,
tb.siope_documento_tipo_desc_bnkit,
tb.siope_documento_tipo_analogico_code,
tb.siope_documento_tipo_analogico_desc,
tb.siope_documento_tipo_analogico_desc_bnkit,
tb.siope_tipo_debito_code,
tb.siope_tipo_debito_desc,
tb.siope_tipo_debito_desc_bnkit,
tb.siope_assenza_motivazione_code,
tb.siope_assenza_motivazione_desc,
tb.siope_assenza_motivazione_desc_bnkit,
tb.siope_scadenza_motivo_code,
tb.siope_scadenza_motivo_desc,
tb.siope_scadenza_motivo_desc_bnkit ,
tb.doc_id,
tb.data_ins_atto_allegato::timestamp,
tb.data_sosp_atto_allegato::timestamp,
tb.causale_sosp_atto_allegato,
tb.data_riattiva_atto_allegato::timestamp,
tb.data_completa_atto_allegato::timestamp,
tb.data_convalida_atto_allegato::timestamp,
-- SIAC-8153  - Sofia 22.06.2021
tb.cod_cdc_sub,
tb.desc_cdc_sub,
tb.cod_cdr_sub,
tb.desc_cdr_sub
-- SIAC-8153  - Sofia 22.06.2021
from (
with doc as (
  with doc1 as
  (
      with
      doc_totale as
      (
        select distinct
        b.doc_gruppo_tipo_id,
        g.ente_proprietario_id, g.ente_denominazione,
        a.doc_anno, a.doc_numero, a.doc_desc, a.doc_importo,
        case when a.doc_beneficiariomult= false then 'F' else 'T' end doc_beneficiariomult,
        a.doc_data_emissione, a.doc_data_scadenza,
        case when a.doc_collegato_cec = false then 'F' else 'T' end doc_collegato_cec,
        f.doc_stato_code, f.doc_stato_desc,
        c.doc_fam_tipo_code, c.doc_fam_tipo_desc, b.doc_tipo_code, b.doc_tipo_desc,
        a.doc_id, a.pcccod_id, a.pccuff_id,
        case when a.doc_contabilizza_genpcc= false then 'F' else 'T' end doc_contabilizza_genpcc,
        h.subdoc_numero, h.subdoc_desc, h.subdoc_importo, h.subdoc_nreg_iva, h.subdoc_data_scadenza,
        h.subdoc_convalida_manuale, h.subdoc_importo_da_dedurre, h.subdoc_splitreverse_importo,
        case when h.subdoc_pagato_cec = false then 'F' else 'T' end subdoc_pagato_cec,
        h.subdoc_data_pagamento_cec,
        a.codbollo_id, h.subdoc_id,h.comm_tipo_id,
        h.notetes_id,h.dist_id,h.contotes_id,
        a.doc_sdi_lotto_siope,
        n.siope_documento_tipo_code, n.siope_documento_tipo_desc, n.siope_documento_tipo_desc_bnkit,
        o.siope_documento_tipo_analogico_code, o.siope_documento_tipo_analogico_desc, o.siope_documento_tipo_analogico_desc_bnkit,
        i.siope_tipo_debito_code, i.siope_tipo_debito_desc, i.siope_tipo_debito_desc_bnkit,
        l.siope_assenza_motivazione_code, l.siope_assenza_motivazione_desc, l.siope_assenza_motivazione_desc_bnkit,
        m.siope_scadenza_motivo_code, m.siope_scadenza_motivo_desc, m.siope_scadenza_motivo_desc_bnkit
        from siac_t_doc a
        left join siac_d_siope_documento_tipo n on n.siope_documento_tipo_id = a.siope_documento_tipo_id
                                           and n.data_cancellazione is null
                                           and n.validita_fine is null
        left join siac_d_siope_documento_tipo_analogico o on o.siope_documento_tipo_analogico_id = a.siope_documento_tipo_analogico_id
                                                   and o.data_cancellazione is null
                                                   and o.validita_fine is null
        ,siac_d_doc_tipo b,siac_d_doc_fam_tipo c,
        siac_r_doc_stato e,
        siac_d_doc_stato f,
        siac_t_ente_proprietario g,
        siac_t_subdoc h
        left join siac_d_siope_tipo_debito i on i.siope_tipo_debito_id = h.siope_tipo_debito_id
                                           and i.data_cancellazione is null
                                           and i.validita_fine is null
        left join siac_d_siope_assenza_motivazione l on l.siope_assenza_motivazione_id = h.siope_assenza_motivazione_id
                                                   and l.data_cancellazione is null
                                                   and l.validita_fine is null
        left join siac_d_siope_scadenza_motivo m on m.siope_scadenza_motivo_id = h.siope_scadenza_motivo_id
                                                   and m.data_cancellazione is null
                                                   and m.validita_fine is null
        where b.doc_tipo_id=a.doc_tipo_id
        and c.doc_fam_tipo_id=b.doc_fam_tipo_id
        and e.doc_id=a.doc_id
        and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
        and f.doc_stato_id=e.doc_stato_id
        and g.ente_proprietario_id=a.ente_proprietario_id
        and g.ente_proprietario_id=p_ente_proprietario_id
        AND c.doc_fam_tipo_code in ('S','IS')
        and h.doc_id=a.doc_id
        and exists
        (
         select 1
         from
         (
         -- 1 - DOC. NON PAGATI - NON PAGATI INTERAMENTE O PAGATI A CAVALLO DI UN ANNO O DA QUELLO SUCCESSIVO
         (
         select distinct a.doc_id
         from  siac_t_bil anno,siac_t_periodo per,
               siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo,
               siac_r_ordinativo_stato rs,siac_d_ordinativo_Stato stato,
               siac_t_ordinativo_ts ts,siac_r_subdoc_ordinativo_ts rsub
         where f.doc_stato_code='EM'
         and   rsub.subdoc_id=h.subdoc_id
         and   ts.ord_ts_id=rsub.ord_ts_id
         and   ord.ord_id=ts.ord_id
         and   tipo.ord_tipo_id=ord.ord_tipo_id
         and   tipo.ord_tipo_code='P'
         and   anno.bil_id=ord.bil_id
         and   per.periodo_id=anno.periodo_id
         and   per.anno::integer<=annoStorico
         and   rs.ord_id=ord.ord_id
         and   stato.ord_stato_id=rs.ord_stato_id
         and   stato.ord_stato_code!='A'
         and   not exists
         (
          select 1
          from siac_t_subdoc sub1,siac_r_subdoc_ordinativo_ts rsub1,
               siac_t_ordinativo_ts ts1,siac_t_ordinativo ord1,
               siac_t_bil anno1,siac_t_periodo per1
          where sub1.doc_id=a.doc_id
          and   rsub1.subdoc_id=sub1.subdoc_id
          and   ts1.ord_ts_id=rsub1.ord_ts_id
          and   ord1.ord_id=ts1.ord_id
          and   anno1.bil_id=ord1.bil_id
          and   per1.periodo_id=anno1.bil_id
          and   per1.anno::integer>=annoStorico+1
          and   rsub1.data_cancellazione is null
          and   rsub1.validita_fine is null
         )
         and   rsub.data_cancellazione is null
         and   rsub.validita_fine is null
         and   ts.data_cancellazione is null
         and   ts.validita_fine is null
         and   rs.data_cancellazione is null
         and   rs.validita_fine is null
         )
         union
         (
          -- 2 DOCUMENTI PAGATI MANUALMENTE
          with
          doc_paga_man as
          (
          select rattr.doc_id,
                 substring(coalesce(rattrDataPAga.testo,'01/01/'||(annoStorico+1)::varchar||''),7,4)::integer annoDataPaga
          from siac_r_doc_attr rattr,siac_t_attr attr,
               siac_r_doc_Stato rs,siac_d_doc_Stato stato,
               siac_r_doc_attr rattrDataPaga,siac_t_attr attrDataPaga
          where rattr.doc_id=a.doc_id
          and   attr.attr_id=rattr.attr_id
          and   attr.attr_code='flagPagataIncassata'
          and   rattr.boolean='S'
          and   rs.doc_id=a.doc_id
          and   stato.doc_stato_id=rs.doc_stato_id
          and   stato.doc_stato_code='EM'
          and   rattrDataPaga.doc_id=a.doc_id
          and   attrDataPaga.attr_id=rattrDataPaga.attr_id
          and   attrdatapaga.attr_code='dataOperazionePagamentoIncasso'
          and   rattr.data_cancellazione is null
          and   rs.data_cancellazione is null
          and   rs.validita_fine is null
          )
          select distinct query_doc_paga_man.doc_id
          from doc_paga_man  query_doc_paga_man
          where query_doc_paga_man.annoDataPaga<=annoStorico
         )
         union
         (
           -- 3 - ANNULLATI IN ANNI ANTECEDENTI
           select a.doc_id
           where  f.doc_stato_code='A'
           and  extract (year from e.validita_inizio)::integer<=annoStorico
         )
         union
         (
           -- 4 - STORNATI IN ANNI ANTECEDENTI
           select a.doc_id
           where f.doc_stato_code='ST'
           and  extract (year from e.validita_inizio)::integer<=annoStorico
         )

         ) doc_storico
        )
        AND a.data_cancellazione IS NULL
        AND b.data_cancellazione IS NULL
        AND c.data_cancellazione IS NULL
        AND e.data_cancellazione IS NULL
        AND f.data_cancellazione IS NULL
        AND g.data_cancellazione IS NULL
        AND h.data_cancellazione IS NULL
     )
     select doc_tot.*
     from doc_totale doc_tot
--     limit 50
)
, docgru as  (
select a.doc_gruppo_tipo_id, a.doc_gruppo_tipo_code, a.doc_gruppo_tipo_desc
 from siac_d_doc_gruppo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null)
select doc1.*, docgru.* from doc1 left join docgru on
docgru.doc_gruppo_tipo_id = doc1.doc_gruppo_tipo_id
  )
  ,bollo as (
  select a.codbollo_id,a.codbollo_code, a.codbollo_desc from siac_d_codicebollo a
  where a.ente_proprietario_id=p_ente_proprietario_id
  and a.data_cancellazione is null)
  ,sogg as (
  with sogg1 as (
  select distinct a.doc_id,b.soggetto_code,
  f.soggetto_stato_desc,
  b.partita_iva, b.codice_fiscale, b.codice_fiscale_estero,
   b.soggetto_id
   from
  siac_r_doc_sog a, siac_t_soggetto b ,siac_r_soggetto_stato e ,siac_d_soggetto_stato f
  where
  a.ente_proprietario_id=p_ente_proprietario_id
  and a.soggetto_id=b.soggetto_id
  and e.soggetto_id=b.soggetto_id
  and f.soggetto_stato_id=e.soggetto_stato_id
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND e.data_cancellazione IS NULL
  AND f.data_cancellazione IS NULL
  ),
  sogg2 as (
  select g.soggetto_id, g.ragione_sociale from  siac_t_persona_giuridica g
  where g.ente_proprietario_id=p_ente_proprietario_id and g.data_cancellazione is null)
  ,sogg3 as (
  select h.soggetto_id,h.nome, h.cognome from siac_t_persona_fisica h
  where h.ente_proprietario_id=p_ente_proprietario_id and h.data_cancellazione is null
  ),
  sogg5 as (select
c.soggetto_id,d.soggetto_tipo_desc
 from siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d where c.ente_proprietario_id=p_ente_proprietario_id and
  d.soggetto_tipo_id=c.soggetto_tipo_id
  and c.data_cancellazione is null
  and d.data_cancellazione is NULL
  AND p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  )
  select sogg1.*, sogg2.ragione_sociale,sogg3.nome, sogg3.cognome, sogg5.soggetto_tipo_desc
  from sogg1 left join sogg2 on sogg1.soggetto_id=sogg2.soggetto_id
  left join sogg3 on sogg1.soggetto_id=sogg3.soggetto_id
  left join sogg5 on sogg1.soggetto_id=sogg5.soggetto_id
  )
  , reguni as (select a.doc_id,a.rudoc_registrazione_anno,
  a.rudoc_registrazione_numero,a.rudoc_registrazione_data
  from siac_t_registrounico_doc a where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  , cdr as (
  select a.doc_id, b.classif_code doc_cdr_cdr_code, b.classif_desc doc_cdr_cdr_desc ,
  null   doc_cdr_cdc_code, null  doc_cdr_cdc_desc
  from siac_r_doc_class a, siac_t_class b, siac_d_class_tipo c
  where a.classif_id=b.classif_id
  and b.classif_tipo_id=c.classif_tipo_id
  and c.classif_tipo_code='CDR'
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  ),
  cdc as (
  select a.doc_id, b.classif_code doc_cdc_cdc_code, b.classif_desc doc_cdc_cdc_desc,
  d.classif_code doc_cdc_cdr_code, d.classif_desc doc_cdc_cdr_desc
  from siac_r_doc_class a, siac_t_class b, siac_d_class_tipo c, siac_t_class d,siac_r_class_fam_tree e
  where a.classif_id=b.classif_id
  and b.classif_tipo_id=c.classif_tipo_id
  and c.classif_tipo_code='CDC'
  and b.classif_id=e.classif_id
  and d.classif_id=e.classif_id_padre
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  AND d.data_cancellazione IS NULL
  AND e.data_cancellazione IS NULL)
  ,pcccod as (select a.pcccod_id,a.pcccod_code,a.pcccod_desc from
  siac_d_pcc_codice  a where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  , pccuff as (
  select a.pccuff_id,a.pccuff_code,a.pccuff_desc from
  siac_d_pcc_ufficio  a where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  , attoamm as (
  with attoamm1 as (
  select
  b.attoamm_id,
  a.subdoc_id,  b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
  d.attoamm_stato_code, d.attoamm_stato_desc,
  e.attoamm_tipo_code, e.attoamm_tipo_desc
  from
  siac_r_subdoc_atto_amm a ,siac_t_atto_amm b ,siac_r_atto_amm_stato c ,siac_d_atto_amm_stato d,
  siac_d_atto_amm_tipo e
  where
  a.ente_proprietario_id=p_ente_proprietario_id and
  a.attoamm_id=b.attoamm_id and c.attoamm_id=b.attoamm_id
  and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  and d.attoamm_stato_id=c.attoamm_stato_id
  and e.attoamm_tipo_id=b.attoamm_tipo_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.data_cancellazione is null
  ),
cdr as (
  select a.attoamm_id, b.classif_code attoamm_cdr_cdr_code, b.classif_desc attoamm_cdr_cdr_desc ,
  null::varchar  attoamm_cdr_cdc_code, null::varchar attoamm_cdr_cdc_desc
  from siac_r_atto_amm_class a, siac_t_class b, siac_d_class_tipo c
  where a.classif_id=b.classif_id
  and b.classif_tipo_id=c.classif_tipo_id
  and c.classif_tipo_code='CDR'
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  ),
  cdc as (
  select a.attoamm_id, b.classif_code attoamm_cdc_cdc_code, b.classif_desc attoamm_cdc_cdc_desc,
  d.classif_code attoamm_cdc_cdr_code, d.classif_desc attoamm_cdc_cdr_desc
  from siac_r_atto_amm_class a, siac_t_class b, siac_d_class_tipo c, siac_t_class d,siac_r_class_fam_tree e
  where a.classif_id=b.classif_id
  and b.classif_tipo_id=c.classif_tipo_id
  and c.classif_tipo_code='CDC'
  and b.classif_id=e.classif_id
  and d.classif_id=e.classif_id_padre
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  AND d.data_cancellazione IS NULL
  AND e.data_cancellazione IS NULL
  )
  select   attoamm1.*,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdc_code::varchar else null::varchar end attoamm_cdc_code,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdc_desc::varchar else null::varchar end attoamm_cdc_desc,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdr_code::varchar else cdr.attoamm_cdr_cdr_code::varchar end attoamm_cdr_code,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdr_desc::varchar else cdr.attoamm_cdr_cdr_desc::varchar end attoamm_cdr_desc
  from attoamm1
  left join cdc on attoamm1.attoamm_id=cdc.attoamm_id
  left join cdr on attoamm1.attoamm_id=cdr.attoamm_id
  ),
  commt as (select a.comm_tipo_id,a.comm_tipo_code,a.comm_tipo_desc
   from siac_d_commissione_tipo a where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  ,
  eldocattall as (
  with eldoc as (
  select a.subdoc_id,a.eldoc_id,
  b.eldoc_anno, b.eldoc_numero, b.eldoc_data_trasmissione, b.eldoc_tot_quoteentrate,
  b.eldoc_tot_quotespese, b.eldoc_tot_dapagare, b.eldoc_tot_daincassare,
  d.eldoc_stato_code, d.eldoc_stato_desc
   from
  siac_r_elenco_doc_subdoc a,siac_t_elenco_doc b, siac_r_elenco_doc_stato c,
  siac_d_elenco_doc_stato d
  where
  a.ente_proprietario_id=p_ente_proprietario_id and
  b.eldoc_id=a.eldoc_id
  and c.eldoc_id=b.eldoc_id
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  and d.eldoc_stato_id=c.eldoc_stato_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  ),
  attoal as (with attoall as (
select distinct
  a.eldoc_id,b.attoal_id,
  b.attoal_causale, b.attoal_altriallegati, b.attoal_dati_sensibili,
         b.attoal_data_scadenza, b.attoal_note, b.attoal_annotazioni, b.attoal_pratica,
         b.attoal_responsabile_amm, b.attoal_responsabile_con, b.attoal_titolario_anno,
         b.attoal_titolario_numero, b.attoal_versione_invio_firma,
         d.attoal_stato_code, d.attoal_stato_desc,
         b.data_creazione data_ins_atto_allegato,
	     fnc_siac_attoal_getDataStato(b.attoal_id,'C') data_completa_atto_allegato,
         fnc_siac_attoal_getDataStato(b.attoal_id,'CV') data_convalida_atto_allegato
   from
  siac_r_atto_allegato_elenco_doc a, siac_t_atto_allegato b,
  siac_r_atto_allegato_stato c ,siac_d_atto_allegato_stato d
  where a.ente_proprietario_id=p_ente_proprietario_id and
  a.attoal_id=b.attoal_id
  and c.attoal_id=b.attoal_id
  and d.attoal_stato_id=c.attoal_stato_id
  and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  ),
  soggattoall as (
  with sogg1 as (
  select distinct a.attoal_id,b.soggetto_code soggetto_code_atto_allegato,
  f.soggetto_stato_desc soggetto_stato_desc_atto_allegato,
  b.partita_iva partita_iva_atto_allegato, b.codice_fiscale codice_fiscale_atto_allegato,
  b.codice_fiscale_estero codice_fiscale_estero_atto_allegato,
  b.soggetto_id soggetto_id_atto_allegato,
  a.attoal_sog_data_sosp data_sosp_atto_allegato,
  a.attoal_sog_causale_sosp causale_sosp_atto_allegato,
  a.attoal_sog_data_riatt data_riattiva_atto_allegato
   from
  siac_r_atto_allegato_sog a, siac_t_soggetto b ,siac_r_soggetto_stato e ,siac_d_soggetto_stato f
  where
  a.ente_proprietario_id=p_ente_proprietario_id
  and a.soggetto_id=b.soggetto_id
  and e.soggetto_id=b.soggetto_id
  and f.soggetto_stato_id=e.soggetto_stato_id
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND e.data_cancellazione IS NULL
  AND f.data_cancellazione IS NULL
  ),
  sogg2 as (
  select g.soggetto_id, g.ragione_sociale  from  siac_t_persona_giuridica g
  where g.ente_proprietario_id=p_ente_proprietario_id and g.data_cancellazione is null)
  ,sogg3 as (
  select h.soggetto_id,h.nome, h.cognome from siac_t_persona_fisica h
  where h.ente_proprietario_id=p_ente_proprietario_id and h.data_cancellazione is null
  ),
  sogg5 as (select
	c.soggetto_id,d.soggetto_tipo_desc
 from siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d where c.ente_proprietario_id=p_ente_proprietario_id and
  d.soggetto_tipo_id=c.soggetto_tipo_id
  and c.data_cancellazione is null
  and d.data_cancellazione is NULL
  AND p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  )
  select sogg1.*, sogg2.ragione_sociale ragione_sociale_atto_allegato,sogg3.nome nome_atto_allegato,
  sogg3.cognome cognome_atto_allegato, sogg5.soggetto_tipo_desc soggetto_tipo_desc_atto_allegato
  from sogg1 left join sogg2 on sogg1.soggetto_id_atto_allegato=sogg2.soggetto_id
  left join sogg3 on sogg1.soggetto_id_atto_allegato=sogg3.soggetto_id
  left join sogg5 on sogg1.soggetto_id_atto_allegato=sogg5.soggetto_id
  )
  select attoall.*,soggattoall.ragione_sociale_atto_allegato,soggattoall.nome_atto_allegato,
  soggattoall.cognome_atto_allegato,   soggattoall.soggetto_code_atto_allegato,
  soggattoall.soggetto_tipo_desc_atto_allegato,
  soggattoall.soggetto_stato_desc_atto_allegato,
  soggattoall.partita_iva_atto_allegato, soggattoall.codice_fiscale_atto_allegato,
  soggattoall.codice_fiscale_estero_atto_allegato,
  soggattoall.soggetto_id_atto_allegato ,
  soggattoall.data_sosp_atto_allegato,
  soggattoall.causale_sosp_atto_allegato,
  soggattoall.data_riattiva_atto_allegato
  from attoall left join soggattoall
  on attoall.attoal_id=soggattoall.attoal_id
  )
  select distinct eldoc.*,
  attoal.attoal_id,
  attoal.attoal_causale, attoal.attoal_altriallegati, attoal.attoal_dati_sensibili,
         attoal.attoal_data_scadenza, attoal.attoal_note, attoal.attoal_annotazioni, attoal.attoal_pratica,
         attoal.attoal_responsabile_amm, attoal.attoal_responsabile_con, attoal.attoal_titolario_anno,
         attoal.attoal_titolario_numero, attoal.attoal_versione_invio_firma,
         attoal.attoal_stato_code, attoal.attoal_stato_desc,
   attoal.ragione_sociale_atto_allegato,attoal.nome_atto_allegato,attoal.cognome_atto_allegato,
   attoal.soggetto_code_atto_allegato,
  attoal.soggetto_tipo_desc_atto_allegato,
  attoal.soggetto_stato_desc_atto_allegato,
  attoal.partita_iva_atto_allegato, attoal.codice_fiscale_atto_allegato,
  attoal.codice_fiscale_estero_atto_allegato,
  attoal.soggetto_id_atto_allegato,
  attoal.data_ins_atto_allegato,
  attoal.data_sosp_atto_allegato,
  attoal.causale_sosp_atto_allegato,
  attoal.data_riattiva_atto_allegato,
  attoal.data_completa_atto_allegato,
  attoal.data_convalida_atto_allegato
  from eldoc left join attoal
  on eldoc.eldoc_id=attoal.eldoc_id
  ),
  notes as (
  select a.notetes_id,a.notetes_desc from
  siac.siac_d_note_tesoriere a
  where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  , dist as (
  select a.dist_id,a.dist_code, a.dist_desc from siac_d_distinta a
  where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  , contes as (
  select a.contotes_id,a.contotes_desc from siac_d_contotesoreria  a
  where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null),
  split as (select
  a.subdoc_id,b.sriva_tipo_code , b.sriva_tipo_desc from  siac_r_subdoc_splitreverse_iva_tipo a,
  siac_d_splitreverse_iva_tipo b
  where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null
  and b.sriva_tipo_id=a.sriva_tipo_id
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  )
  , liq as (  select  a.subdoc_id,b.liq_anno,b.liq_numero ,d.liq_stato_desc
  from siac.siac_r_subdoc_liquidazione a ,siac_t_liquidazione b,siac_r_liquidazione_stato c ,
  siac_d_liquidazione_stato d
  where a.ente_proprietario_id=p_ente_proprietario_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and b.liq_id=a.liq_id
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  and c.liq_id=b.liq_id
  and d.liq_stato_id=c.liq_stato_id
  and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
),
subcltipoavviso as (select a.subdoc_id,b.classif_code cod_tipo_avviso,b.classif_desc desc_tipo_avviso
 from siac_r_subdoc_class a, siac_t_class b,siac_d_class_tipo c
where a.ente_proprietario_id=p_ente_proprietario_id and b.classif_id=a.classif_id
and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and c.classif_tipo_id=b.classif_tipo_id
and c.classif_tipo_code='TIPO_AVVISO'
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
),
docattr1 as (
SELECT distinct a.doc_id,
a.testo v_registro_repertorio
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'registro_repertorio' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr2 as (
SELECT distinct a.doc_id,
a.numerico v_anno_repertorio
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'anno_repertorio' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr3 as (
SELECT distinct a.doc_id,
a.testo v_num_repertorio
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'num_repertorio' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr4 as (
SELECT distinct a.doc_id,
a.testo v_data_repertorio
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'data_repertorio' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr5 as (
SELECT distinct a.doc_id,
a.testo v_data_ricezione_portale
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'dataRicezionePortale' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr6 as (
SELECT distinct a.doc_id,
a.testo v_dataOperazionePagamentoIncasso
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'dataOperazionePagamentoIncasso' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr7 as (
SELECT distinct a.doc_id,
a."boolean" v_flagPagataIncassata
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagPagataIncassata' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr8 as (
SELECT distinct a.doc_id,
a.testo v_notePagamentoIncasso
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'notePagamentoIncasso' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr9 as (
SELECT distinct a.doc_id,
a.numerico v_arrotondamento
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'arrotondamento' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)

,subdocattr1 as (
SELECT distinct a.subdoc_id,
a."boolean" v_rilevante_iva
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagRilevanteIVA' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr2 as (
SELECT a.subdoc_id, a.subdoc_attr_id,
a."boolean" v_ordinativo_singolo
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagOrdinativoSingolo' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)

,subdocattr3 as (
SELECT distinct a.subdoc_id,
a."boolean" v_esproprio
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagEsproprio' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr4 as (
SELECT distinct a.subdoc_id,
a."boolean" v_certificazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagCertificazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr5 as (
SELECT distinct a.subdoc_id,
a."boolean" v_ordinativo_manuale
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagOrdinativoManuale' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr6 as (
SELECT distinct a.subdoc_id,
a."boolean" v_avviso
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagAvviso' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr7 as (
SELECT distinct a.subdoc_id,
a.numerico v_num_mutuo
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'numeroMutuo' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr8 as (
SELECT distinct a.subdoc_id,
a.testo v_cup
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'cup' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr9 as (
SELECT distinct a.subdoc_id,
a.testo v_cig
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'cig' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr10 as (
SELECT distinct a.subdoc_id,
a.testo v_note_certificazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'noteCertificazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr12 as (
SELECT distinct a.subdoc_id,
a.testo v_data_esecuzione_pagamento
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'dataEsecuzionePagamento' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr13 as (
SELECT distinct a.subdoc_id,
a.testo v_annotazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'annotazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr14 as (
SELECT distinct a.subdoc_id,
a.testo v_num_certificazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'numeroCertificazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr15 as (
SELECT distinct a.subdoc_id,
a.testo v_data_scadenza_dopo_sospensione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'dataScadenzaDopoSospensione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr17 as (
SELECT distinct a.subdoc_id,
a.testo v_causale_ordinativo
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'causaleOrdinativo' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr18 as (
SELECT distinct a.subdoc_id,
a.testo v_note
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'Note' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr19 as (
SELECT distinct a.subdoc_id,
a.testo v_data_certificazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'dataCertificazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,soggsub as (
  with sogg1 as (
  select distinct a.subdoc_id,b.soggetto_code soggetto_code_subdoc,
  f.soggetto_stato_desc soggetto_stato_desc_subdoc,
  b.partita_iva partita_iva_subdoc, b.codice_fiscale codice_fiscale_subdoc,
  b.codice_fiscale_estero codice_fiscale_estero_subdoc,
   b.soggetto_id soggetto_id_subdoc
   from
  siac_r_subdoc_sog a, siac_t_soggetto b ,siac_r_soggetto_stato e ,siac_d_soggetto_stato f
  where
  a.ente_proprietario_id=p_ente_proprietario_id
  and a.soggetto_id=b.soggetto_id
  and e.soggetto_id=b.soggetto_id
  and f.soggetto_stato_id=e.soggetto_stato_id
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
    AND e.data_cancellazione IS NULL
  AND f.data_cancellazione IS NULL
  ),
  sogg2 as (
  select g.soggetto_id, g.ragione_sociale ragione_sociale_subdoc  from  siac_t_persona_giuridica g
  where g.ente_proprietario_id=p_ente_proprietario_id and g.data_cancellazione is null)
  ,sogg3 as (
  select h.soggetto_id,h.nome nome_subdoc, h.cognome cognome_subdoc from siac_t_persona_fisica h
  where h.ente_proprietario_id=p_ente_proprietario_id and h.data_cancellazione is null
  ),
  sogg4 as (
  SELECT a.soggetto_id_da, a.soggetto_id_a
    FROM siac.siac_r_soggetto_relaz a, siac.siac_d_relaz_tipo b
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and
    a.relaz_tipo_id = b.relaz_tipo_id
    AND   b.relaz_tipo_code  = 'SEDE_SECONDARIA'
    AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
    AND   p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
    AND   a.data_cancellazione IS NULL
    AND   b.data_cancellazione IS NULL)
    ,
sogg5 as (select
c.soggetto_id,d.soggetto_tipo_desc soggetto_tipo_desc_subdoc
 from siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d where c.ente_proprietario_id=p_ente_proprietario_id and
  d.soggetto_tipo_id=c.soggetto_tipo_id
  and c.data_cancellazione is null
  and d.data_cancellazione is NULL
  AND p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  )
  select sogg1.*, sogg2.ragione_sociale_subdoc,sogg3.nome_subdoc, sogg3.cognome_subdoc,
  case when sogg4.soggetto_id_da is not null then 'S' else NULL::varchar end v_sede_secondaria_subdoc
  , sogg5.soggetto_tipo_desc_subdoc
  from sogg1 left join sogg2 on sogg1.soggetto_id_subdoc=sogg2.soggetto_id
  left join sogg3 on sogg1.soggetto_id_subdoc=sogg3.soggetto_id
  left join sogg4 on sogg1.soggetto_id_subdoc=sogg4.soggetto_id_a
  left join sogg5 on sogg1.soggetto_id_subdoc=sogg5.soggetto_id
  ),
  imp as (select distinct
  c.movgest_id,b.movgest_ts_id,
a.subdoc_id,
case when g.movgest_ts_tipo_code ='T' then b.movgest_ts_code else NULL::varchar end v_cod_impegno,
case when g.movgest_ts_tipo_code ='T' then c.movgest_desc else NULL::varchar end v_desc_impegno,
case when g.movgest_ts_tipo_code ='S' then b.movgest_ts_code else NULL::varchar end v_cod_subimpegno,
case when g.movgest_ts_tipo_code ='S' then b.movgest_ts_desc else NULL::varchar end v_desc_subimpegno,
e.anno v_bil_anno,
c.movgest_anno v_anno_impegno,
c.movgest_numero v_num_impegno,
g.movgest_ts_tipo_code
from
siac_r_subdoc_movgest_ts a, siac_t_movgest_ts b, siac_t_movgest c, siac_t_bil d,
siac_t_periodo e, siac_d_movgest_tipo f, siac_d_movgest_ts_tipo g
where b.movgest_ts_id=A.movgest_ts_id
and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and c.movgest_id=b.movgest_id
and d.bil_id=c.bil_id
and e.periodo_id=d.periodo_id
and f.movgest_tipo_id=c.movgest_tipo_id
and g.movgest_ts_tipo_id=b.movgest_ts_tipo_id
and f.movgest_tipo_code = 'I'
and a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null),
modpag as (
with modpag0 as (
with modpag1 as (
SELECT
a.subdoc_id,b.quietanziante, b.quietanzante_nascita_data, b.quietanziante_nascita_luogo, b.quietanziante_nascita_stato,
b.bic, b.contocorrente ,b.contocorrente_intestazione,b.iban , b.note , b.data_scadenza,b.accredito_tipo_id,
 b.soggetto_id,a.soggrelmpag_id, b.modpag_id
FROM siac.siac_r_subdoc_modpag a, siac.siac_t_modpag b where
a.ente_proprietario_id=p_ente_proprietario_id and
b.modpag_id = a.modpag_id
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is NULL
and b.data_cancellazione is NULL
)
,actipo as (
select a.accredito_tipo_id,
a.accredito_tipo_code ,
a.accredito_tipo_desc
 from siac.siac_d_accredito_tipo a where a.ente_proprietario_id=p_ente_proprietario_id and
a.data_cancellazione is NULL),
relmodpag as ( SELECT
 a.soggrelmpag_id,
b.soggetto_id_a v_soggetto_id_modpag_cess
 FROM  siac.siac_r_soggrel_modpag a, siac.siac_r_soggetto_relaz b
 WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.soggetto_relaz_id = b.soggetto_relaz_id
 AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
 AND   a.data_cancellazione IS NULL
 AND   p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
 AND   b.data_cancellazione IS NULL
 )
 select
modpag1.subdoc_id,
modpag1.quietanziante v_quietanziante,
modpag1.quietanzante_nascita_data v_data_nasciata_quietanziante,
modpag1.quietanziante_nascita_luogo v_luogo_nascita_quietanziante,
modpag1.quietanziante_nascita_stato v_stato_nascita_quietanziante,
modpag1.bic v_bic, modpag1.contocorrente v_contocorrente,
modpag1.contocorrente_intestazione v_intestazione_contocorrente,
modpag1.iban v_iban, modpag1.note v_note_mod_pag, modpag1.data_scadenza v_data_scadenza_mod_pag,
modpag1.accredito_tipo_id,
 modpag1.soggetto_id v_soggetto_id_modpag_nocess,
modpag1.soggrelmpag_id v_soggrelmpag_id, modpag1.modpag_id v_mod_pag_id,
actipo.accredito_tipo_code v_cod_tipo_accredito,
actipo.accredito_tipo_desc v_desc_tipo_accredito,
case when modpag1.soggrelmpag_id IS NULL THEN modpag1.soggetto_id else relmodpag.v_soggetto_id_modpag_cess
 end v_soggetto_id_modpag
 from modpag1 left join actipo
on modpag1.accredito_tipo_id=actipo.accredito_tipo_id
left join relmodpag on relmodpag.soggrelmpag_id=modpag1.soggrelmpag_id
)
,
 soggmodpag as (
  with sogg1 as (
  select distinct b.soggetto_code, d.soggetto_tipo_desc, f.soggetto_stato_desc,
  b.partita_iva, b.codice_fiscale, b.codice_fiscale_estero,
   b.soggetto_id
   from
  siac_t_soggetto b ,siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d,siac_r_soggetto_stato e ,siac_d_soggetto_stato f
  where
  b.ente_proprietario_id=p_ente_proprietario_id
  and c.soggetto_id=b.soggetto_id
  and d.soggetto_tipo_id=c.soggetto_tipo_id
  and e.soggetto_id=b.soggetto_id
  and f.soggetto_stato_id=e.soggetto_stato_id
  and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  AND d.data_cancellazione IS NULL
  AND e.data_cancellazione IS NULL
  AND f.data_cancellazione IS NULL
  ),
  sogg2 as (
  select g.soggetto_id, g.ragione_sociale from  siac_t_persona_giuridica g
  where g.ente_proprietario_id=p_ente_proprietario_id and g.data_cancellazione is null)
  ,sogg3 as (
  select h.soggetto_id,h.nome, h.cognome from siac_t_persona_fisica h
  where h.ente_proprietario_id=p_ente_proprietario_id and h.data_cancellazione is null
  )
  select sogg1.*, sogg2.ragione_sociale,sogg3.nome, sogg3.cognome
  from sogg1 left join sogg2 on sogg1.soggetto_id=sogg2.soggetto_id
  left join sogg3 on sogg1.soggetto_id=sogg3.soggetto_id
  )
select modpag0.*,soggmodpag.soggetto_code v_cod_sogg_mod_pag, soggmodpag.soggetto_tipo_desc v_tipo_sogg_mod_pag,
soggmodpag.soggetto_stato_desc v_stato_sogg_mod_pag, soggmodpag.ragione_sociale v_rag_sociale_sogg_mod_pag,
soggmodpag.partita_iva v_p_iva_sogg_mod_pag, soggmodpag.codice_fiscale v_cf_sogg_mod_pag,
soggmodpag.codice_fiscale_estero v_cf_estero_sogg_mod_pag,
soggmodpag.nome v_nome_sogg_mod_pag, soggmodpag.cognome v_cognome_sogg_mod_pag
 from modpag0
left join soggmodpag on soggmodpag.soggetto_id=modpag0.v_soggetto_id_modpag
),
ord as (
SELECT
a.subdoc_id,
c.ord_anno, c.ord_numero, b.ord_ts_code, g.anno
    FROM  siac_r_subdoc_ordinativo_ts a, siac_t_ordinativo_ts b, siac_t_ordinativo c,
          siac_r_ordinativo_stato d, siac_d_ordinativo_stato e,
          siac.siac_t_bil f, siac.siac_t_periodo g
    WHERE b.ord_ts_id = a.ord_ts_id
    AND   c.ord_id = b.ord_id
    AND   d.ord_id = c.ord_id
    AND   d.ord_stato_id = e.ord_stato_id
    AND   c.bil_id = f.bil_id
    AND   g.periodo_id = f.periodo_id
    AND   e.ord_stato_code <> 'A'
    AND   a.data_cancellazione IS NULL
    AND   b.data_cancellazione IS NULL
    AND   c.data_cancellazione IS NULL
    AND   d.data_cancellazione IS NULL
    AND   e.data_cancellazione IS NULL
    AND   f.data_cancellazione IS NULL
    AND   g.data_cancellazione IS NULL
    AND   p_data between a.validita_inizio and COALESCE(a.validita_fine,p_data)
    AND   p_data between d.validita_inizio and COALESCE(d.validita_fine,p_data)
    ),
  -- SIAC-8153  - Sofia 22.06.2021
  cdc_subdoc AS
  (
  SELECT c.classif_code cod_cdc_sub,c.classif_desc desc_cdc_sub, rc.subdoc_id
  FROM siac_r_subdoc_class rc,siac_t_class c,siac_d_class_tipo tipo
  WHERE tipo.ente_proprietario_id=p_ente_proprietario_id
  AND   tipo.classif_tipo_code='CDC'
  AND   c.classif_tipo_id=tipo.classif_tipo_id
  AND   rc.classif_id=c.classif_id
  AND   rc.data_cancellazione IS NULL
  AND   p_data between rc.validita_inizio and COALESCE(rc.validita_fine,p_data)
  ),
  cdr_subdoc AS
  (
  SELECT c.classif_code cod_cdr_sub,c.classif_desc desc_cdr_sub, rc.subdoc_id
  FROM siac_r_subdoc_class rc,siac_t_class c,siac_d_class_tipo tipo
  WHERE tipo.ente_proprietario_id=p_ente_proprietario_id
  AND   tipo.classif_tipo_code='CDR'
  AND   c.classif_tipo_id=tipo.classif_tipo_id
  AND   rc.classif_id=c.classif_id
  AND   rc.data_cancellazione IS NULL
  AND   p_data between rc.validita_inizio and COALESCE(rc.validita_fine,p_data)
  )
  -- SIAC-8153  - Sofia 22.06.2021
  select doc.ente_proprietario_id v_ente_proprietario_id,
  doc.ente_denominazione v_ente_denominazione,
  doc.subdoc_id,
  doc.doc_anno v_anno_doc, doc.doc_numero v_num_doc,
  doc.doc_desc v_desc_doc,
  doc.doc_importo v_importo_doc,
  doc.doc_beneficiariomult v_beneficiario_multiplo_doc,
  doc.doc_data_emissione v_data_emissione_doc,
  doc.doc_data_scadenza v_data_scadenza_doc,
  bollo.codbollo_code v_codice_bollo_doc, bollo.codbollo_desc v_desc_codice_bollo_doc,
 doc.doc_collegato_cec v_collegato_cec_doc,
  pcccod.pcccod_code v_cod_pcc_doc,pcccod.pcccod_desc v_desc_pcc_doc
  ,pccuff.pccuff_code v_cod_ufficio_doc,pccuff.pccuff_desc v_desc_ufficio_doc,
  doc.doc_stato_code v_cod_stato_doc, doc.doc_stato_desc v_desc_stato_doc,
   doc.doc_fam_tipo_code v_cod_famiglia_doc, doc.doc_fam_tipo_desc v_desc_famiglia_doc,
doc.doc_tipo_code v_cod_tipo_doc, doc.doc_tipo_desc v_desc_tipo_doc,
doc.subdoc_numero v_num_subdoc, doc.subdoc_desc v_desc_subdoc,doc.subdoc_importo v_importo_subdoc,
doc.subdoc_nreg_iva v_num_reg_iva_subdoc, doc.subdoc_data_scadenza v_data_scadenza_subdoc,
doc.subdoc_convalida_manuale v_convalida_manuale_subdoc, doc.subdoc_importo_da_dedurre v_importo_da_dedurre_subdoc,
doc.subdoc_splitreverse_importo v_splitreverse_importo_subdoc,
doc.subdoc_pagato_cec v_pagato_cec_subdoc,
doc.subdoc_data_pagamento_cec v_data_pagamento_cec_subdoc,
doc.doc_contabilizza_genpcc v_doc_contabilizza_genpcc,
sogg.soggetto_id v_sogg_id_doc,sogg.soggetto_code v_cod_sogg_doc, sogg.soggetto_tipo_desc v_tipo_sogg_doc,
sogg.soggetto_stato_desc v_stato_sogg_doc,sogg.ragione_sociale v_rag_sociale_sogg_doc,
sogg.partita_iva v_p_iva_sogg_doc,
sogg.codice_fiscale v_cf_sogg_doc,
sogg.codice_fiscale_estero v_cf_estero_sogg_doc,
sogg.nome v_nome_sogg_doc, sogg.cognome v_cognome_sogg_doc,
reguni.rudoc_registrazione_anno,reguni.rudoc_registrazione_numero,reguni.rudoc_registrazione_data,
case when cdr.doc_cdr_cdr_code is not null then null::varchar else cdc.doc_cdc_cdc_code::varchar end cdc_code,
case when cdr.doc_cdr_cdr_code is not null then null::varchar else cdc.doc_cdc_cdc_desc::varchar end cdc_desc,
case when cdr.doc_cdr_cdr_code is not null then cdr.doc_cdr_cdr_code::varchar else cdc.doc_cdc_cdr_code::varchar end cdr_code,
case when cdr.doc_cdr_cdr_code is not null then cdr.doc_cdr_cdr_desc::varchar else cdc.doc_cdc_cdr_desc::varchar end cdr_desc,
attoamm.attoamm_anno v_anno_atto_amministrativo, attoamm.attoamm_numero v_num_atto_amministrativo,
attoamm.attoamm_oggetto v_oggetto_atto_amministrativo, attoamm.attoamm_note v_note_atto_amministrativo,
attoamm.attoamm_stato_code v_cod_stato_atto_amministrativo, attoamm.attoamm_stato_desc v_desc_stato_atto_amministrativo,
attoamm.attoamm_tipo_code v_cod_tipo_atto_amministrativo, attoamm.attoamm_tipo_desc v_desc_tipo_atto_amministrativo,
attoamm.attoamm_cdc_code v_cod_cdc_atto_amministrativo,attoamm.attoamm_cdc_desc v_desc_cdc_atto_amministrativo,
attoamm.attoamm_cdr_code v_cod_cdr_atto_amministrativo,attoamm.attoamm_cdr_desc v_desc_cdr_atto_amministrativo,
commt.comm_tipo_code,commt.comm_tipo_desc v_tipo_commissione_subdoc,
eldocattall.subdoc_id,eldocattall.eldoc_id,
eldocattall.eldoc_anno v_anno_elenco_doc,
eldocattall.eldoc_numero v_num_elenco_doc,
eldocattall.eldoc_data_trasmissione v_data_trasmissione_elenco_doc,
eldocattall.eldoc_tot_quoteentrate v_tot_quote_entrate_elenco_doc,
eldocattall.eldoc_tot_quotespese v_tot_quote_spese_elenco_doc,
eldocattall.eldoc_tot_dapagare v_tot_da_pagare_elenco_doc,
eldocattall.eldoc_tot_daincassare v_tot_da_incassare_elenco_doc,
eldocattall.eldoc_stato_code v_cod_stato_elenco_doc,
eldocattall.eldoc_stato_desc v_desc_stato_elenco_doc,
eldocattall.attoal_id,
eldocattall.attoal_causale v_causale_atto_allegato,
eldocattall.attoal_altriallegati v_altri_allegati_atto_allegato, eldocattall.attoal_dati_sensibili v_dati_sensibili_atto_allegato,
eldocattall.attoal_data_scadenza v_data_scadenza_atto_allegato, eldocattall.attoal_note v_note_atto_allegato,
eldocattall.attoal_annotazioni v_annotazioni_atto_allegato, eldocattall.attoal_pratica v_pratica_atto_allegato,
eldocattall.attoal_responsabile_amm v_resp_amm_atto_allegato, eldocattall.attoal_responsabile_con v_resp_contabile_atto_allegato,
eldocattall.attoal_titolario_anno v_anno_titolario_atto_allegato,
eldocattall.attoal_titolario_numero v_num_titolario_atto_allegato, eldocattall.attoal_versione_invio_firma v_vers_invio_firma_atto_allegato,
eldocattall.attoal_stato_code v_cod_stato_atto_allegato, eldocattall.attoal_stato_desc v_desc_stato_atto_allegato,
eldocattall.ragione_sociale_atto_allegato v_rag_sociale_sogg_atto_allegato,
eldocattall.nome_atto_allegato v_nome_sogg_atto_allegato,
eldocattall.cognome_atto_allegato v_cognome_sogg_atto_allegato,
eldocattall.soggetto_code_atto_allegato v_cod_sogg_atto_allegato,
eldocattall.soggetto_tipo_desc_atto_allegato v_tipo_sogg_atto_allegato,
eldocattall.soggetto_stato_desc_atto_allegato v_stato_sogg_atto_allegato,
eldocattall.partita_iva_atto_allegato v_p_iva_sogg_atto_allegato,
eldocattall.codice_fiscale_atto_allegato v_cf_sogg_atto_allegato,
eldocattall.codice_fiscale_estero_atto_allegato v_cf_estero_sogg_atto_allegato,
eldocattall.soggetto_id_atto_allegato v_sogg_id_atto_allegato,
doc.doc_gruppo_tipo_code v_cod_gruppo_doc, doc.doc_gruppo_tipo_desc v_desc_gruppo_doc,
notes.notetes_desc v_note_tesoriere_subdoc,
dist.dist_code v_cod_distinta_subdoc, dist.dist_desc v_desc_distinta_subdoc,
contes.contotes_desc v_conto_tesoreria_subdoc,
split.sriva_tipo_code v_cod_tipo_splitrev , split.sriva_tipo_desc v_desc_tipo_splitrev,
liq.liq_anno v_anno_liquidazione,liq.liq_numero v_num_liquidazione,liq.liq_stato_desc v_liq_stato_desc,
subcltipoavviso.cod_tipo_avviso v_cod_tipo_avviso,subcltipoavviso.desc_tipo_avviso v_desc_tipo_avviso,
docattr1.v_registro_repertorio,
docattr2.v_anno_repertorio,
docattr3.v_num_repertorio,
docattr4.v_data_repertorio,
docattr5.v_data_ricezione_portale,
docattr6.v_dataOperazionePagamentoIncasso,
docattr7.v_flagPagataIncassata,
docattr8.v_notePagamentoIncasso,
docattr9.v_arrotondamento,
subdocattr1.v_rilevante_iva,
subdocattr2.v_ordinativo_singolo,
subdocattr3.v_esproprio,
subdocattr4.v_certificazione,
subdocattr5.v_ordinativo_manuale,
subdocattr6.v_avviso,
subdocattr7.v_num_mutuo,
subdocattr8.v_cup,
subdocattr9.v_cig,
subdocattr10.v_note_certificazione,
null::varchar v_data_sospensione,
subdocattr12.v_data_esecuzione_pagamento,
subdocattr13.v_annotazione,
subdocattr14.v_num_certificazione,
subdocattr15.v_data_scadenza_dopo_sospensione,
null::varchar v_data_riattivazione,
subdocattr17.v_causale_ordinativo,
subdocattr18.v_note,
subdocattr19.v_data_certificazione,
null::varchar v_causale_sospensione,
soggsub.soggetto_code_subdoc v_cod_sogg_subdoc,
soggsub.soggetto_tipo_desc_subdoc v_tipo_sogg_subdoc,
soggsub.soggetto_stato_desc_subdoc v_stato_sogg_subdoc,
soggsub.partita_iva_subdoc v_p_iva_sogg_subdoc,
soggsub.codice_fiscale_subdoc v_cf_sogg_subdoc,
soggsub.codice_fiscale_estero_subdoc v_cf_estero_sogg_subdoc,
soggsub.soggetto_id_subdoc v_soggetto_id,
soggsub.nome_subdoc v_nome_sogg_subdoc,
soggsub.cognome_subdoc v_cognome_sogg_subdoc, soggsub.ragione_sociale_subdoc v_rag_sociale_sogg_subdoc,
soggsub.v_sede_secondaria_subdoc v_sede_secondaria_subdoc,
imp.v_cod_impegno v_cod_impegno,
imp.v_desc_impegno v_desc_impegno,
imp.v_cod_subimpegno v_cod_subimpegno,
imp.v_desc_subimpegno v_desc_subimpegno,
imp.v_bil_anno v_bil_anno,
imp.v_anno_impegno v_anno_impegno,
imp.v_num_impegno v_num_impegno,
imp.movgest_ts_tipo_code,
modpag.v_quietanziante v_quietanziante,
modpag.v_data_nasciata_quietanziante,
modpag.v_luogo_nascita_quietanziante,
modpag.v_stato_nascita_quietanziante,
modpag.v_bic, modpag.v_contocorrente,
modpag.v_intestazione_contocorrente,
modpag.v_iban, modpag.v_note_mod_pag, modpag.v_data_scadenza_mod_pag,
modpag.accredito_tipo_id,
modpag.v_soggetto_id_modpag_nocess,
modpag.v_soggrelmpag_id, modpag.v_mod_pag_id,
modpag.v_cod_tipo_accredito v_cod_tipo_accredito,
modpag.v_desc_tipo_accredito v_desc_tipo_accredito,
modpag.v_soggetto_id_modpag,
modpag.v_cod_sogg_mod_pag, modpag.v_tipo_sogg_mod_pag,
modpag.v_stato_sogg_mod_pag, modpag.v_rag_sociale_sogg_mod_pag,
modpag.v_p_iva_sogg_mod_pag, modpag.v_cf_sogg_mod_pag,
modpag.v_cf_estero_sogg_mod_pag,
modpag.v_nome_sogg_mod_pag, modpag.v_cognome_sogg_mod_pag,
ord.subdoc_id,
ord.ord_anno v_anno_ord, ord.ord_numero v_num_ord, ord.ord_ts_code v_num_subord, ord.anno v_bil_anno_ord,
doc.doc_sdi_lotto_siope,
doc.siope_documento_tipo_code, doc.siope_documento_tipo_desc, doc.siope_documento_tipo_desc_bnkit,
doc.siope_documento_tipo_analogico_code, doc.siope_documento_tipo_analogico_desc, doc.siope_documento_tipo_analogico_desc_bnkit,
doc.siope_tipo_debito_code, doc.siope_tipo_debito_desc, doc.siope_tipo_debito_desc_bnkit,
doc.siope_assenza_motivazione_code, doc.siope_assenza_motivazione_desc, doc.siope_assenza_motivazione_desc_bnkit,
doc.siope_scadenza_motivo_code, doc.siope_scadenza_motivo_desc, doc.siope_scadenza_motivo_desc_bnkit,
doc.doc_id,
eldocattall.data_ins_atto_allegato,
eldocattall.data_sosp_atto_allegato,
eldocattall.causale_sosp_atto_allegato,
eldocattall.data_riattiva_atto_allegato,
eldocattall.data_completa_atto_allegato,
eldocattall.data_convalida_atto_allegato,
-- SIAC-8153 Sofia 22.06.2021
cdc_subdoc.cod_cdc_sub,
cdc_subdoc.desc_cdc_sub,
cdr_subdoc.cod_cdr_sub,
cdr_subdoc.desc_cdr_sub
-- SIAC-8153 Sofia 22.06.2021
from doc
left join bollo on doc.codbollo_id=bollo.codbollo_id
left join sogg on doc.doc_id=sogg.doc_id
left join reguni on doc.doc_id=reguni.doc_id
left join cdc on doc.doc_id=cdc.doc_id
left join cdr on doc.doc_id=cdr.doc_id
left join pcccod on doc.pcccod_id=pcccod.pcccod_id
left join pccuff on doc.pccuff_id=pccuff.pccuff_id
left join attoamm on doc.subdoc_id=attoamm.subdoc_id
left join commt on doc.comm_tipo_id=commt.comm_tipo_id
left join eldocattall on doc.subdoc_id=eldocattall.subdoc_id
left join notes on doc.notetes_id=notes.notetes_id
left join dist  on doc.dist_id=dist.dist_id
left join contes on doc.contotes_id=contes.contotes_id
left join split on doc.subdoc_id=split.subdoc_id
left join liq on doc.subdoc_id=liq.subdoc_id
left join  subcltipoavviso on doc.subdoc_id=subcltipoavviso.subdoc_id
left join docattr1 on doc.doc_id=docattr1.doc_id
left join docattr2 on doc.doc_id=docattr2.doc_id
left join docattr3 on doc.doc_id=docattr3.doc_id
left join docattr4 on doc.doc_id=docattr4.doc_id
left join docattr5 on doc.doc_id=docattr5.doc_id
left join docattr6 on doc.doc_id=docattr6.doc_id
left join docattr7 on doc.doc_id=docattr7.doc_id
left join docattr8 on doc.doc_id=docattr8.doc_id
left join docattr9 on doc.doc_id=docattr9.doc_id
left join subdocattr1 on doc.subdoc_id=subdocattr1.subdoc_id
left join subdocattr2 on doc.subdoc_id=subdocattr2.subdoc_id
left join subdocattr3 on doc.subdoc_id=subdocattr3.subdoc_id
left join subdocattr4 on doc.subdoc_id=subdocattr4.subdoc_id
left join subdocattr5 on doc.subdoc_id=subdocattr5.subdoc_id
left join subdocattr6 on doc.subdoc_id=subdocattr6.subdoc_id
left join subdocattr7 on doc.subdoc_id=subdocattr7.subdoc_id
left join subdocattr8 on doc.subdoc_id=subdocattr8.subdoc_id
left join subdocattr9 on doc.subdoc_id=subdocattr9.subdoc_id
left join subdocattr10 on doc.subdoc_id=subdocattr10.subdoc_id
left join subdocattr12 on doc.subdoc_id=subdocattr12.subdoc_id
left join subdocattr13 on doc.subdoc_id=subdocattr13.subdoc_id
left join subdocattr14 on doc.subdoc_id=subdocattr14.subdoc_id
left join subdocattr15 on doc.subdoc_id=subdocattr15.subdoc_id
left join subdocattr17 on doc.subdoc_id=subdocattr17.subdoc_id
left join subdocattr18 on doc.subdoc_id=subdocattr18.subdoc_id
left join subdocattr19 on doc.subdoc_id=subdocattr19.subdoc_id
left join soggsub on soggsub.subdoc_id = doc.subdoc_id
left join imp on imp.subdoc_id=doc.subdoc_id
left join modpag on modpag.subdoc_id=doc.subdoc_id
left join ord on ord.subdoc_id = doc.subdoc_id
-- SIAC-8153 Sofia 22.06.2021
LEFT JOIN cdc_subdoc ON cdc_subdoc.subdoc_id=doc.subdoc_id
LEFT JOIN cdr_subdoc ON cdr_subdoc.subdoc_id=doc.subdoc_id
-- SIAC-8153 Sofia 22.06.2021
) as tb;

esito:= 'Fine funzione carico storico documenti spesa  (FNC_SIAC_DWH_ST_DOCUMENTO_SPESA) - '||clock_timestamp();
RETURN NEXT;

update siac_dwh_log_elaborazioni log
set    fnc_elaborazione_fine = clock_timestamp(),
       fnc_durata=clock_timestamp()-log.fnc_elaborazione_inizio,
       fnc_parameters=log.fnc_parameters||' - '||esito
where fnc_user=v_user_table;


EXCEPTION
WHEN others THEN
  esito:='Funzione carico storico documenti spesa (FNC_SIAC_DWH_ST_DOCUMENTO_SPESA) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

alter FUNCTION siac.fnc_siac_dwh_documento_spesa(integer,timestamp) owner to siac;
alter FUNCTION siac.fnc_siac_dwh_st_documento_spesa(integer,timestamp) owner to siac;
-- 23.06.2021 Sofia SIAC-8153 - fine

--SIAC-8139 - Maurizio - INIZIO

DROP FUNCTION if exists siac."BILR227_Allegato_7_delibera_variazione_variabili_bozza_Prev"(p_ente_prop_id integer, p_anno varchar, p_numero_delibera integer, p_anno_delibera varchar, p_tipo_delibera varchar, p_anno_competenza varchar, p_ele_variazioni varchar);

CREATE OR REPLACE FUNCTION siac."BILR227_Allegato_7_delibera_variazione_variabili_bozza_Prev" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar
)
RETURNS TABLE (
  id_capitolo integer,
  tipologia_capitolo varchar,
  stanziato numeric,
  variazione_aumento numeric,
  variazione_diminuzione numeric,
  anno_riferimento varchar,
  display_error varchar
) AS
$body$
DECLARE

classifBilRec record;


annoCapImp varchar;
tipoAvanzo varchar;
tipoDisavanzo varchar;
tipoFpvcc varchar;
tipoFpvsc varchar;
elemTipoCodeE varchar;
elemTipoCodeS varchar;
h_count integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
fase_bilancio varchar;
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
strQuery varchar;
tipoFci varchar;

BEGIN

annoCapImp:= p_anno; 

tipoAvanzo='AAM';
tipoDisavanzo='DAM';
tipoFpvcc='FPVCC';
tipoFpvsc='FPVSC';
tipoFci='FCI';

-- 04/04/2019: il report funziona solo per la previsione
elemTipoCodeE:='CAP-EP'; -- tipo capitolo previsione
elemTipoCodeS:='CAP-UP'; -- tipo capitolo previsione

id_capitolo=0;
tipologia_capitolo='';
stanziato=0;
variazione_aumento=0;
variazione_diminuzione=0;
anno_riferimento='';
display_error:='';


--SIAC-6163: 16/05/2018.
-- Introdotti il paramentro p_ele_variazioni  con l'elenco delle 
-- variazioni.
-- Introdotti i controlli sui parametri.
-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 intApp = strApp::numeric;
END IF;

contaParametriParz:=0;
contaParametri:=0;

if p_numero_delibera IS NOT NULL THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_anno_delibera IS NOT NULL AND p_anno_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_tipo_delibera IS NOT NULL AND p_tipo_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;

if contaParametriParz = 1 OR contaParametriParz = 2 then
	display_error:= 'ERRORE NEI PARAMETRI: Specificare tutti i dati relativi al parametro ''Provvedimento di variazione''';
    return next;
    return;
elsif contaParametriParz = 3 THEN -- parametro corretto
	contaParametri := contaParametri + 1;
end if;

contaParametriParz:=0;

if (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
	contaParametri := contaParametri + 1;
end if;


if contaParametri = 0 THEN
	display_error:= 'ERRORE NEI PARAMETRI: Specificare un parametro tra ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
elsif contaParametri = 2 THEN    
	display_error:= 'ERRORE NEI PARAMETRI: Specificare uno solo tra i parametri ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
end if;


select fnc_siac_random_user()
into	user_table;

 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep''.';  

insert into siac_rep_cap_eg
select null,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente
 from 	siac_t_bil_elem e,
        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code 	in (elemTipoCodeE,elemTipoCodeS)
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
-- INC000001570761 and	stato_capitolo.elem_stato_code		=	'VA'	
and	stato_capitolo.elem_stato_code		in ('VA', 'PR')
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
--28/06/2021 SIAC-8139
--Aggiunto tipoFci
and	cat_del_capitolo.elem_cat_code	in (tipoAvanzo,tipoDisavanzo,
	tipoFpvcc,tipoFpvsc,tipoFci)
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null;


 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep_imp''.';  

insert into siac_rep_cap_eg_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            cat_del_capitolo.elem_cat_code			tipo_imp,
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
        and	anno_eserc.anno						= 	p_anno 												
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		in (elemTipoCodeE,elemTipoCodeS)
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id
        and	capitolo_imp_tipo.elem_det_tipo_code	=	'STA' 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        --and	capitolo_imp_periodo.anno in (annoCapImp)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		-- INC000001570761 and	stato_capitolo.elem_stato_code		=	'VA'	
        and	stato_capitolo.elem_stato_code		in ('VA', 'PR')
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
            --28/06/2021 SIAC-8139
            --Aggiunto tipoFci        
		and	cat_del_capitolo.elem_cat_code		in (tipoAvanzo,tipoDisavanzo,tipoFpvcc,tipoFpvsc,tipoFci)	
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
    group by capitolo_importi.elem_id,cat_del_capitolo.elem_cat_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente;
   
     RTN_MESSAGGIO:='preparazione tabella importi variazioni ''.';  

            
--SIAC-6163: 16/05/2018.
-- la query cambia a seconda del tipo parametro: atto/numeri di variazioni.
if p_numero_delibera IS NOT NULL THEN
  insert into siac_rep_var_entrate
	(elem_id, importo, utente, ente_proprietario, periodo_anno)
  select	dettaglio_variazione.elem_id,
          sum(dettaglio_variazione.elem_det_importo), -- 30.08.2017 siac-5203 Sofia - aggiunto sum
          --------cat_del_capitolo.elem_cat_code,     -- 30.08.2017 siac-5203 Sofia - commentato
          user_table utente,
          atto.ente_proprietario_id,
          anno_importo.anno	      	
  from 	siac_t_atto_amm 			atto,
          siac_d_atto_amm_tipo		tipo_atto,
          siac_r_atto_amm_stato 		r_atto_stato,
          siac_d_atto_amm_stato 		stato_atto,
          siac_r_variazione_stato		r_variazione_stato,
          siac_t_variazione 			testata_variazione,
          siac_d_variazione_tipo		tipologia_variazione,
          siac_d_variazione_stato 	tipologia_stato_var,
          siac_t_bil_elem_det_var 	dettaglio_variazione,
          siac_t_bil_elem				capitolo,
          siac_d_bil_elem_tipo 		tipo_capitolo,
          siac_d_bil_elem_det_tipo	tipo_elemento,
          siac_d_bil_elem_categoria 	cat_del_capitolo, 
          siac_r_bil_elem_categoria 	r_cat_capitolo,
          siac_t_periodo 				anno_eserc,
          siac_t_periodo              anno_importo ,
          siac_t_bil                  bilancio  
  where 	atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
  and		r_atto_stato.attoamm_id								=	atto.attoamm_id
  and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
  and		( r_variazione_stato.attoamm_id						=	atto.attoamm_id or
            r_variazione_stato.attoamm_id_varbil				=	atto.attoamm_id)
  and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
  and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
  and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id			
  and     anno_eserc.periodo_id                               = bilancio.periodo_id
  and     testata_variazione.bil_id                           = bilancio.bil_id 
  and     capitolo.bil_id                                     = bilancio.bil_id 
  and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
  and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
  and		dettaglio_variazione.elem_id						=	capitolo.elem_id
  and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
  and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
  and		capitolo.elem_id									=	r_cat_capitolo.elem_id
  and		r_cat_capitolo.elem_cat_id							=	cat_del_capitolo.elem_cat_id
  -- 15/06/2016: cambiati i tipi di variazione. Aggiunto 'AS'.
  --and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF')
  -- 19/07/2016: tolto il test sul tipo di variazione: accettate tutte.
  --and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF', 'AS')
  and		atto.ente_proprietario_id 							= 	p_ente_prop_id
  and		anno_eserc.anno										= 	p_anno 		
  and		atto.attoamm_numero 								= 	p_numero_delibera
  and		atto.attoamm_anno									=	p_anno_delibera
  and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera
  and		tipologia_stato_var.variazione_stato_tipo_code		in	('B','G', 'C', 'P')										
  and     anno_importo.anno                                   =   p_anno_competenza					
  and		tipo_capitolo.elem_tipo_code						in (elemTipoCodeE,elemTipoCodeS)
  and		tipo_elemento.elem_det_tipo_code					= 'STA'
    --28/06/2021 SIAC-8139
    --Aggiunto tipoFci  
  and		cat_del_capitolo.elem_cat_code	in (tipoAvanzo,tipoDisavanzo,
  		tipoFpvcc,tipoFpvsc,tipoFci)	
  and		atto.data_cancellazione						is null
  and		tipo_atto.data_cancellazione				is null
  and		r_atto_stato.data_cancellazione				is null
  and		stato_atto.data_cancellazione				is null
  and		r_variazione_stato.data_cancellazione		is null
  and		testata_variazione.data_cancellazione		is null
  and		tipologia_variazione.data_cancellazione		is null
  and		tipologia_stato_var.data_cancellazione		is null
  and 	dettaglio_variazione.data_cancellazione		is null
  and 	capitolo.data_cancellazione					is null
  and		tipo_capitolo.data_cancellazione			is null
  and		tipo_elemento.data_cancellazione			is null
  and		cat_del_capitolo.data_cancellazione			is null 
  and     r_cat_capitolo.data_cancellazione			is null
  group by 	dettaglio_variazione.elem_id, -- -- 30.08.2017 siac-5203 Sofia aggiunto group by per sum
              utente,
              atto.ente_proprietario_id,
              anno_importo.anno;
else
	strQuery:='
    	insert into siac_rep_var_entrate
	(elem_id, importo, utente, ente_proprietario, periodo_anno)
          select	dettaglio_variazione.elem_id,
          sum(dettaglio_variazione.elem_det_importo),
          '''||user_table||''' utente,
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
          siac_d_bil_elem_categoria 	cat_del_capitolo, 
          siac_r_bil_elem_categoria 	r_cat_capitolo,
          siac_t_periodo 				anno_eserc,
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
  and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
  and		capitolo.elem_id									=	r_cat_capitolo.elem_id
  and		r_cat_capitolo.elem_cat_id							=	cat_del_capitolo.elem_cat_id
  and		testata_variazione.ente_proprietario_id 			= 	'||p_ente_prop_id||'
  and 	testata_variazione.variazione_num 						in   ('||p_ele_variazioni||')
  and		anno_eserc.anno										= 	'''||p_anno||''' 		
  and		tipologia_stato_var.variazione_stato_tipo_code		in	(''B'',''G'', ''C'', ''P'')										
  and     anno_importo.anno                                   =   '''||p_anno_competenza||'''					
  and		tipo_capitolo.elem_tipo_code						in ('''||elemTipoCodeE||''','''||elemTipoCodeS||''')
  and		tipo_elemento.elem_det_tipo_code					= ''STA''
    --28/06/2021 SIAC-8139
    --Aggiunto tipoFci    
  and		cat_del_capitolo.elem_cat_code						in ('''||tipoAvanzo||''','''||tipoDisavanzo||''','''||tipoFpvcc||''','''||tipoFpvsc||''','''||tipoFci||''')	
  and		r_variazione_stato.data_cancellazione		is null
  and		testata_variazione.data_cancellazione		is null
  and		tipologia_variazione.data_cancellazione		is null
  and		tipologia_stato_var.data_cancellazione		is null
  and 	dettaglio_variazione.data_cancellazione		is null
  and 	capitolo.data_cancellazione					is null
  and		tipo_capitolo.data_cancellazione			is null
  and		tipo_elemento.data_cancellazione			is null
  and		cat_del_capitolo.data_cancellazione			is null 
  and     r_cat_capitolo.data_cancellazione			is null
  group by 	dettaglio_variazione.elem_id, 
              utente,
              testata_variazione.ente_proprietario_id,
              anno_importo.anno'; 

raise notice 'strQuery = %', strQuery;

execute strQuery;                    
end if;                  	                          
    
     RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  

insert into siac_rep_var_entrate_riga
select  tb0.elem_id,       
		tb1.importo        as 		variazione_aumento_stanziato,
        tb2.importo        as 		variazione_diminuzione_stanziato,
        0,
        0,
        0,
        0,
        user_table utente,
        p_ente_prop_id,
        p_anno
from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
        --and tb1.tipologia  	= 'STA'	
        and 	tb1.importo > 0	
        and     tb1.periodo_anno=p_anno
        and     tb1.utente = tb0.utente
         ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	--and tb2.tipologia  	= 'STA'	
        AND	tb2.importo < 0	
        and tb2.periodo_anno =p_anno 
         and     tb2.utente = tb0.utente)
    where  tb0.utente = user_table 
  union 
  select  tb0.elem_id,       
		tb1.importo        as 		variazione_aumento_stanziato,
        tb2.importo        as 		variazione_diminuzione_stanziato,
        0,
        0,
        0,
        0,
        user_table utente,
        p_ente_prop_id,
        (p_anno::INTEGER + 1)::varchar
    from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
        --and tb1.tipologia  	= 'STA'	
        and 	tb1.importo > 0	
        and     tb1.periodo_anno=(p_anno::INTEGER + 1)::varchar
        and     tb1.utente = tb0.utente
         ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	--and tb2.tipologia  	= 'STA'	
        AND	tb2.importo < 0	
        and tb2.periodo_anno =(p_anno::INTEGER + 1)::varchar 
         and     tb2.utente = tb0.utente)
    where  tb0.utente = user_table 
  union 
  select  tb0.elem_id,       
		tb1.importo        as 		variazione_aumento_stanziato,
        tb2.importo        as 		variazione_diminuzione_stanziato,
        0,
        0,
        0,
        0,
        user_table utente,
        p_ente_prop_id,
        (p_anno::INTEGER + 2)::varchar
    from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
        --and tb1.tipologia  	= 'STA'	
        and 	tb1.importo > 0	
        and     tb1.periodo_anno=(p_anno::INTEGER + 2)::varchar
        and     tb1.utente = tb0.utente
         ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	--and tb2.tipologia  	= 'STA'	
        AND	tb2.importo < 0	
        and tb2.periodo_anno =(p_anno::INTEGER + 2)::varchar 
         and     tb2.utente = tb0.utente)
    where  tb0.utente = user_table 
     ;

     RTN_MESSAGGIO:='preparazione file output ''.';          

for classifBilRec in
select 	tb1.elem_id   		 											id_capitolo,
       	tb1.tipo_imp    												tipologia_capitolo,
       	tb1.importo     												stanziato,
       	COALESCE (tb2.variazione_aumento_stanziato,0)     				variazione_aumento,
       	COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)			variazione_diminuzione,
        tb1.periodo_anno                                                anno_riferimento          
from  	siac_rep_cap_eg_imp tb1  
            left	join    siac_rep_var_entrate_riga tb2  
            on (tb2.elem_id	=	tb1.elem_id
                    and tb1.periodo_anno=tb2.periodo_anno
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table) 
    where tb1.utente = user_table

loop

id_capitolo := classifBilRec.id_capitolo;
tipologia_capitolo := classifBilRec.tipologia_capitolo;
stanziato := classifBilRec.stanziato;

variazione_aumento := classifBilRec.variazione_aumento;
variazione_diminuzione := classifBilRec.variazione_diminuzione;
anno_riferimento := classifBilRec.anno_riferimento;

return next;

end loop;

return next;

delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;
delete from siac_rep_cap_eg where utente=user_table;
delete from siac_rep_cap_eg_imp where utente=user_table;
delete from siac_rep_cap_eg_imp_riga where utente=user_table;
delete from	siac_rep_var_entrate	where utente=user_table;
delete from siac_rep_var_entrate_riga where utente=user_table; 


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
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

--SIAC-8139 - Maurizio - FINE

-- SIAC-8236 Alessandro T. - INIZIO

CREATE OR REPLACE FUNCTION siac.fnc_siac_consultadettaglioimpegno(movgest_ts_id_in integer, OUT tot_imp_liq numeric, OUT n_liq integer, OUT tot_imp_subdoc numeric, OUT n_imp_doc integer, OUT tot_imp_liq_sudoc numeric, OUT n_doc_liq integer, OUT tot_doc_non_liq numeric, OUT n_doc_non_liq integer, OUT tot_imp_predoc numeric, OUT n_imp_predoc integer, OUT tot_imp_cartac numeric, OUT n_cartac integer, OUT tot_imp_cartac_subdoc numeric, OUT n_cartac_subdoc integer, OUT tot_carte_non_reg numeric, OUT n_carte_non_reg integer, OUT tot_mod_prov numeric, OUT tot_imp_cec_no_giust numeric, OUT tot_imp2_no_giust numeric, OUT tot_imp2_giust_integrato numeric, OUT tot_imp2_giust_restituito numeric, OUT tot_imp_cec_fattura numeric, OUT tot_imp_cec_paf_fatt numeric, OUT tot_cec numeric)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN



tot_imp_liq :=0.0; 
n_liq :=0;
tot_imp_subdoc :=0.0;
n_imp_doc :=0;
tot_imp_liq_sudoc :=0.0;
n_doc_liq :=0;
tot_doc_non_liq :=0.0;
n_doc_non_liq :=0;
tot_imp_predoc :=0.0;
n_imp_predoc :=0;
tot_imp_cartac:=0.0;
n_cartac :=0;
tot_imp_cartac_subdoc :=0.0; 
n_cartac_subdoc :=0;
tot_carte_non_reg:=0.0;
n_carte_non_reg:=0;
tot_mod_prov:=0.0;
tot_imp_cec_no_giust:=0.0;
tot_imp2_no_giust:=0.0;
tot_imp2_giust_integrato :=0.0;
tot_imp2_giust_restituito :=0.0;
tot_imp_cec_fattura:=0.0;
tot_imp_cec_paf_fatt :=0.0;
tot_cec :=0.0;



/* ===================================> LIQUIDAZIONI  <================================ */
select coalesce(sum(b.liq_importo),0), coalesce(count(*),0)  into tot_imp_liq , n_liq
from
siac_r_liquidazione_movgest a, siac_t_liquidazione b, siac_d_liquidazione_stato c,
siac_r_liquidazione_stato d
where
a.movgest_ts_id = movgest_ts_id_in
and a.liq_id = b.liq_id
and a.data_cancellazione is null
and now() between  a.validita_inizio  and coalesce(a.validita_fine, now()) 
and b.data_cancellazione is null
and now() between  b.validita_inizio  and coalesce(b.validita_fine, now())
and c.data_cancellazione is null
and now() between  c.validita_inizio  and coalesce(c.validita_fine, now())
and d.data_cancellazione is null
and now() between  d.validita_inizio  and coalesce(d.validita_fine, now())
and b.liq_id = d.liq_id
and d.liq_stato_id = c.liq_stato_id
and c.liq_stato_code <> 'A';
/* ================================> tot_imp_liq => totLiq, n_liq => nLiq  <============================== */

/* ****************************************************************************************** */

/* ==================================> DOCUMENTI NON LIQUIDATI <============================= */
-- somma (importo - importoDaDedurre) subdocumenti di spesa collegati al movgest:  in stato <> A
-- SOMMA IMPORTO DOCUMENTI (al netto di varie deduzioni)
 select coalesce(sum(a1.subdoc_importo - coalesce(a1.subdoc_importo_da_dedurre,0)),0), count(distinct a1.subdoc_id) --SIAC-8236 eseguo la count() dei subdoc_id per intercettare le quote 
 into tot_imp_subdoc, n_imp_doc
 from
    siac_r_subdoc_movgest_ts a, siac_t_subdoc a1,  siac_t_doc a2, siac_d_doc_stato a3, siac_r_doc_stato a4,
    siac_d_doc_tipo a5
    where
    a.movgest_ts_id =  movgest_ts_id_in
    and a.subdoc_id = a1.subdoc_id
    and a1.doc_id = a2.doc_id
    and a4.doc_id = a2.doc_id
    and a4.doc_stato_id = a3.doc_stato_id
    and a3.doc_stato_code != 'A' and  a3.doc_stato_code != 'ST'
	and a2.doc_tipo_id=a5.doc_tipo_id
    and a5.doc_tipo_code <> 'NCD' -- non le note di credito
    and a5.data_cancellazione is null
    and a.data_cancellazione is null
    and now() between  a.validita_inizio  
    and coalesce(a.validita_fine, now())
   	and a1.data_cancellazione is null
    and now() between  a1.validita_inizio 
     and coalesce(a1.validita_fine, now()) 
   	and a2.data_cancellazione is null
    and now() between  a2.validita_inizio 
     and coalesce(a2.validita_fine, now()) 
      	and a3.data_cancellazione is null
    and now() between  a3.validita_inizio 
     and coalesce(a3.validita_fine, now())
   	and a4.data_cancellazione is null
    and now() between  a4.validita_inizio 
     and coalesce(a4.validita_fine, now())
    ;
    
-- LIQUIDATO SU SUBDOCUMENTI con COUNT
  select coalesce(sum(b.liq_importo),0), count(distinct s.subdoc_id)  into tot_imp_liq_sudoc, n_doc_liq --SIAC-8236 eseguo la count() dei subdoc_id per intercettare le quote
from
siac_r_liquidazione_movgest a, siac_t_liquidazione b,
siac_r_subdoc_liquidazione e,
siac_r_liquidazione_stato c,siac_d_liquidazione_stato d, siac_t_subdoc s
where
a.movgest_ts_id = movgest_ts_id_in
and s.subdoc_id = e.subdoc_id
and a.liq_id = e.liq_id
and a.liq_id = b.liq_id
and a.data_cancellazione is null
and now() between  a.validita_inizio 
and coalesce(a.validita_fine, now()) 
and b.data_cancellazione is null
and now() between  b.validita_inizio 
and coalesce(b.validita_fine, now())
and e.data_cancellazione is null
and now() between  e.validita_inizio 
and coalesce(e.validita_fine, now()) 
and c.liq_id=a.liq_id 
and c.liq_stato_id=d.liq_stato_id
and d.liq_stato_code<>'A'
and now() between  c.validita_inizio 
and coalesce(c.validita_fine, now()); 

-- ==> TOTALE DOCUMENTI NON LIQUIDATI <==
tot_doc_non_liq := tot_imp_subdoc - tot_imp_liq_sudoc;
n_doc_non_liq := n_imp_doc - n_doc_liq;
/* =========================> tot_doc_non_liq => totDoc , n_doc_non_liq => nDoc <===================== */

/* ****************************************************************************************** */

/* ===================================> PREDOC NON LIQUIDATI <=============================== */
select coalesce(sum (a1.predoc_importo),0), coalesce(count (*),0)  into tot_imp_predoc, n_imp_predoc
from
siac_r_predoc_movgest_ts a, siac_t_predoc a1, siac_d_predoc_stato a3, siac_r_predoc_stato a4
where
a.movgest_ts_id = movgest_ts_id_in
and a.predoc_id = a1.predoc_id
and a1.predoc_id = a4.predoc_id
and a4.predoc_stato_id = a3.predoc_stato_id
and (a3.predoc_stato_code = 'I' or  a3.predoc_stato_code = 'C')
and a.data_cancellazione is null
and now() between  a.validita_inizio 
and coalesce(a.validita_fine, now()) 
and a1.data_cancellazione is null
and now() between  a1.validita_inizio 
and coalesce(a1.validita_fine, now()) 
and a3.data_cancellazione is null
and now() between  a3.validita_inizio 
and coalesce(a3.validita_fine, now())
and a4.data_cancellazione is null
and now() between  a4.validita_inizio 
and coalesce(a4.validita_fine, now())
;
/* ========================> tot_imp_predoc => totPredoc , n_imp_predoc => nPredoc <=========================== */

/* *************************************************************************** */

/* ===================================> CARTE NON LIQUIDATE <=============================== */
-- somma righe carta contabile collegate al movgest : carta in stato <> A
select  coalesce(sum(a1.cartac_det_importo),0), coalesce(count(*),0)  into tot_imp_cartac, n_cartac
from
siac_r_cartacont_det_movgest_ts a, siac_t_cartacont_det a1, siac_t_cartacont a2 ,
siac_d_cartacont_stato a3, siac_r_cartacont_stato a4
where
a.movgest_ts_id =  movgest_ts_id_in
and a.cartac_det_id = a1.cartac_det_id
and a1.cartac_id = a2.cartac_id
and a2.cartac_id = a4.cartac_id
and a3.cartac_stato_id = a4.cartac_stato_id
and a3.cartac_stato_code != 'A'
and a.data_cancellazione is null
and now() between  a.validita_inizio 
and coalesce(a.validita_fine, now()) 
and a1.data_cancellazione is null
and now() between  a1.validita_inizio 
and coalesce(a1.validita_fine, now())
and a2.data_cancellazione is null
and now() between  a2.validita_inizio 
and coalesce(a2.validita_fine, now()) 
and a3.data_cancellazione is null
and now() between  a3.validita_inizio
 and coalesce(a3.validita_fine, now()) 
and a4.data_cancellazione is null
and now() between  a4.validita_inizio
 and coalesce(a4.validita_fine, now()) 
;
-- somma subdoc della carta
select coalesce(sum(b1.subdoc_importo - b1.subdoc_importo_da_dedurre),0), coalesce(count(*),0) into tot_imp_cartac_subdoc, n_cartac_subdoc
from
siac_r_cartacont_det_movgest_ts a, siac_t_cartacont_det a1, siac_t_cartacont a2, siac_d_cartacont_stato a3, siac_r_cartacont_stato a4,
siac_r_cartacont_det_subdoc b, siac_t_subdoc b1
where
a.movgest_ts_id =  movgest_ts_id_in
and a.cartac_det_id = a1.cartac_det_id
and a1.cartac_det_id = b.cartac_det_id
and b.subdoc_id = b1.subdoc_id
and a1.cartac_id = a2.cartac_id
and a2.cartac_id = a4.cartac_id
and a3.cartac_stato_id = a4.cartac_stato_id
and a3.cartac_stato_code != 'A' 
and a1.cartac_det_id = b.cartac_det_id
and a.data_cancellazione is null
and now() between  a.validita_inizio 
and coalesce(a.validita_fine, now())
and a1.data_cancellazione is null
and now() between  a1.validita_inizio
 and coalesce(a1.validita_fine, now()) 
and a2.data_cancellazione is null
and now() between  a2.validita_inizio 
and coalesce(a2.validita_fine, now()) 
and a3.data_cancellazione is null
and now() between  a3.validita_inizio
 and coalesce(a3.validita_fine, now()) 
and a4.data_cancellazione is null
and now() between  a4.validita_inizio
and coalesce(a4.validita_fine, now()) 
and b.data_cancellazione is null
and now() between  b.validita_inizio
 and coalesce(b.validita_fine, now()) 
 and b1.data_cancellazione is null
and now() between  b1.validita_inizio
 and coalesce(b1.validita_fine, now()) 
;
-- ==> TOTALE CARTE NON REGOLARIZZATE
tot_carte_non_reg := tot_imp_cartac - tot_imp_cartac_subdoc;
n_carte_non_reg := n_cartac - n_cartac_subdoc;
/* =====================> tot_carte_non_reg => totCarte, n_carte_non_reg => nCarte <======================== */

/* *************************************************************************** */

/* ===================================> MODIFICHE POSITIVE PROVVISORIE <=============================== */
-- somma modifiche positive Valide ma con provvedimento provvisorio
select coalesce(sum(c.movgest_ts_det_importo),0) into tot_mod_prov
from siac_t_modifica a, siac_r_modifica_stato b,
siac_t_movgest_ts_det_mod c, siac_t_movgest_ts_det d,
siac_t_movgest_ts e, siac_d_modifica_stato f, siac_t_atto_amm g,
siac_r_atto_amm_stato h, siac_d_atto_amm_stato i
where
e.movgest_ts_id = movgest_ts_id_in
and f.mod_stato_code = 'V' -- la modifica deve essere valida
and i.attoamm_stato_code = 'PROVVISORIO' -- atto provvisorio
and c.movgest_ts_det_importo > 0 -- importo positivo
--
and a.mod_id = b.mod_id
and c.mod_stato_r_id = b.mod_stato_r_id
and d.movgest_ts_det_id = c.movgest_ts_det_id
and e.movgest_ts_id = d.movgest_ts_id
and f.mod_stato_id = b.mod_stato_id
and a.attoamm_id = g.attoamm_id
and g.attoamm_id = h.attoamm_id
and h.attoamm_stato_id = i.attoamm_stato_id
-- date
and a.data_cancellazione is null
and now() between a.validita_inizio and coalesce(a.validita_fine, now())
and b.data_cancellazione is null
and now() between b.validita_inizio and coalesce(b.validita_fine, now())
and c.data_cancellazione is null
and now() between c.validita_inizio and coalesce(c.validita_fine, now())
and d.data_cancellazione is null
and now() between d.validita_inizio and coalesce(d.validita_fine, now())
and e.data_cancellazione is null
and now() between e.validita_inizio and coalesce(e.validita_fine, now())
and f.data_cancellazione is null
and now() between f.validita_inizio and coalesce(f.validita_fine, now())
and g.data_cancellazione is null
and now() between g.validita_inizio and coalesce(g.validita_fine, now())
and h.data_cancellazione is null
and now() between h.validita_inizio and coalesce(h.validita_fine, now())
and i.data_cancellazione is null;

/* =========================> tot_mod_prov => totMod <===================== */

/* *************************************************************************** */

/* ==================================>  CEC <=============================================== */

select sum (ricecon_importo) into 
tot_imp_cec_no_giust
from siac_t_richiesta_econ ec 
, siac_r_richiesta_econ_stato st, siac_d_richiesta_econ_stato ds
where 
st.ricecon_id=ec.ricecon_id
and st.ricecon_stato_id=ds.ricecon_stato_id
and ds.ricecon_stato_code<>'AN'
and now() between st.validita_inizio and COALESCE(st.validita_fine,now()) and
ec.ricecon_id in (
select distinct b.ricecon_id
 from siac_r_richiesta_econ_movgest a, 
 siac_t_richiesta_econ b, siac_t_movimento c,siac_d_richiesta_econ_tipo d
WHERE
b.ricecon_id=a.ricecon_id
and c.ricecon_id=b.ricecon_id
and d.ricecon_tipo_id=b.ricecon_tipo_id
AND d.ricecon_tipo_code IN
('RIMBORSO_SPESE',
'ANTICIPO_TRASFERTA_DIPENDENTI',
'PAGAMENTO')
and a.movgest_ts_id=movgest_ts_id_in
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and not exists (select 1 from siac_r_movimento_stampa z where z.movt_id=c.movt_id and z.data_cancellazione is null)
and not exists (
select 1 from  siac_t_subdoc x,siac_r_richiesta_econ_subdoc y, siac_t_movimento u
where x.subdoc_id=y.subdoc_id and 
y.ricecon_id=u.ricecon_id and 
c.movt_id=u.movt_id
 )
)
and st.data_cancellazione is null
and ds.data_cancellazione is null
and ec.data_cancellazione is null
;

if tot_imp_cec_no_giust is null THEN
tot_imp_cec_no_giust:=0.0;
end if;

raise notice 'cec tot_imp_cec_no_giust:%',tot_imp_cec_no_giust; 


select sum (ricecon_importo) into 
tot_imp2_no_giust
from siac_t_richiesta_econ ec 
, siac_r_richiesta_econ_stato st, siac_d_richiesta_econ_stato ds
where 
st.ricecon_id=ec.ricecon_id
and st.ricecon_stato_id=ds.ricecon_stato_id
and ds.ricecon_stato_code<>'AN'
and now() between st.validita_inizio and COALESCE(st.validita_fine,now()) and
ec.ricecon_id in (
select distinct b.ricecon_id
 from siac_r_richiesta_econ_movgest a, siac_t_richiesta_econ b, siac_t_movimento c,siac_d_richiesta_econ_tipo d
WHERE
b.ricecon_id=a.ricecon_id
and c.ricecon_id=b.ricecon_id
and d.ricecon_tipo_id=b.ricecon_tipo_id
AND d.ricecon_tipo_code IN
('ANTICIPO_SPESE','ANTICIPO_SPESE_MISSIONE')
and a.movgest_ts_id=movgest_ts_id_in
and not exists (select 1 from siac_t_giustificativo z where z.gst_id=c.gst_id and 
  (z.rend_importo_integrato > 0 or z.rend_importo_restituito>0))
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null  
and not exists (select 1 from siac_r_movimento_stampa z where z.movt_id=c.movt_id and z.data_cancellazione is null)
)
and st.data_cancellazione is null
and ds.data_cancellazione is null
and ec.data_cancellazione is null
;

if tot_imp2_no_giust is null THEN
tot_imp2_no_giust:=0.0;
end if;

raise notice 'cec tot_imp2_no_giust:%',tot_imp2_no_giust; 

 select 
sum(e.rend_importo_integrato) into 
tot_imp2_giust_integrato
 from siac_r_richiesta_econ_movgest a, siac_t_richiesta_econ b, siac_t_movimento c,siac_d_richiesta_econ_tipo d,
 siac_t_giustificativo e,
 siac_r_richiesta_econ_stato st, siac_d_richiesta_econ_stato ds
where 
st.ricecon_id=b.ricecon_id
and st.ricecon_stato_id=ds.ricecon_stato_id
and ds.ricecon_stato_code<>'AN'
and now() between st.validita_inizio and COALESCE(st.validita_fine,now()) and
--WHERE
b.ricecon_id=a.ricecon_id
and c.ricecon_id=b.ricecon_id
and d.ricecon_tipo_id=b.ricecon_tipo_id
AND d.ricecon_tipo_code IN
('ANTICIPO_SPESE','ANTICIPO_SPESE_MISSIONE')
and a.movgest_ts_id=movgest_ts_id_in
and e.gst_id=c.gst_id and e.rend_importo_integrato>0
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null 
and e.data_cancellazione is null 
and st.data_cancellazione is null
and ds.data_cancellazione is null
and not exists (select 1 from siac_r_movimento_stampa z where z.movt_id=c.movt_id and z.data_cancellazione is null);


  
if tot_imp2_giust_integrato is null THEN
tot_imp2_giust_integrato:=0.0;
end if;  

raise notice 'cec tot_imp2_giust_integrato:%',tot_imp2_giust_integrato; 

select 
sum(e.rend_importo_restituito) into 
tot_imp2_giust_restituito
 from siac_r_richiesta_econ_movgest a, siac_t_richiesta_econ b, siac_t_movimento c,siac_d_richiesta_econ_tipo d,
 siac_t_giustificativo e,
 siac_r_richiesta_econ_stato st, siac_d_richiesta_econ_stato ds
where 
st.ricecon_id=b.ricecon_id
and st.ricecon_stato_id=ds.ricecon_stato_id
and ds.ricecon_stato_code<>'AN'
and now() between st.validita_inizio and COALESCE(st.validita_fine,now()) and
--WHERE
b.ricecon_id=a.ricecon_id
and c.ricecon_id=b.ricecon_id
and d.ricecon_tipo_id=b.ricecon_tipo_id
AND d.ricecon_tipo_code IN
('ANTICIPO_SPESE','ANTICIPO_SPESE_MISSIONE')
and a.movgest_ts_id=movgest_ts_id_in
and e.gst_id=c.gst_id and e.rend_importo_restituito>0
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null 
and e.data_cancellazione is null
and st.data_cancellazione is null
and ds.data_cancellazione is null
and not exists (select 1 from siac_r_movimento_stampa z where z.movt_id=c.movt_id and z.data_cancellazione is null);

if tot_imp2_giust_restituito is null THEN
tot_imp2_giust_restituito:=0.0;
end if;  

raise notice 'cec tot_imp2_giust_restituito:%',tot_imp2_giust_restituito; 

------pagamento fatture

select sum (ricecon_importo) into 
tot_imp_cec_fattura
from siac_t_richiesta_econ ec, siac_r_richiesta_econ_stato st, siac_d_richiesta_econ_stato ds
where 
st.ricecon_id=ec.ricecon_id
and st.ricecon_stato_id=ds.ricecon_stato_id
and ds.ricecon_stato_code<>'AN'
and now() between st.validita_inizio and COALESCE(st.validita_fine,now()) and
ec.ricecon_id in (
      select distinct b.ricecon_id
      from siac_r_richiesta_econ_movgest a, 
      siac_t_richiesta_econ b, siac_t_movimento c,siac_d_richiesta_econ_tipo d
      WHERE
      b.ricecon_id=a.ricecon_id
      and c.ricecon_id=b.ricecon_id
      and d.ricecon_tipo_id=b.ricecon_tipo_id
      AND d.ricecon_tipo_code IN
      ('PAGAMENTO_FATTURE')
      and a.movgest_ts_id=movgest_ts_id_in
      and a.data_cancellazione is null
      and b.data_cancellazione is null
      and c.data_cancellazione is null
      and d.data_cancellazione is null			
      and exists (select 1 from siac_r_movimento_stampa z where 
      z.movt_id=c.movt_id and z.data_cancellazione is null)
 )
and st.data_cancellazione is null
and ds.data_cancellazione is null
and ec.data_cancellazione is null
;

if tot_imp_cec_fattura is null THEN
tot_imp_cec_fattura:=0.0;
end if;

raise notice 'cec tot_imp_cec_fattura:%',tot_imp_cec_fattura; 



---
select sum (ricecon_importo) into 
tot_imp_cec_paf_fatt
from siac_t_richiesta_econ ec 
, siac_r_richiesta_econ_stato st, siac_d_richiesta_econ_stato ds
where 
st.ricecon_id=ec.ricecon_id
and st.ricecon_stato_id=ds.ricecon_stato_id
and ds.ricecon_stato_code<>'AN'
and now() between st.validita_inizio and COALESCE(st.validita_fine,now()) and
ec.ricecon_id in (
select distinct b.ricecon_id
 from siac_r_richiesta_econ_movgest a, 
 siac_t_richiesta_econ b, siac_t_movimento c,siac_d_richiesta_econ_tipo d
WHERE
b.ricecon_id=a.ricecon_id
and c.ricecon_id=b.ricecon_id
and d.ricecon_tipo_id=b.ricecon_tipo_id
AND d.ricecon_tipo_code IN
('PAGAMENTO')
and a.movgest_ts_id=movgest_ts_id_in
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and exists (select 1 from siac_r_movimento_stampa z where z.movt_id=c.movt_id and z.data_cancellazione is null)
and exists (
select 1 from  siac_t_subdoc x,siac_r_richiesta_econ_subdoc y, siac_t_movimento u
where x.subdoc_id=y.subdoc_id and 
y.ricecon_id=u.ricecon_id and 
c.movt_id=u.movt_id
 )
)
and st.data_cancellazione is null
and ds.data_cancellazione is null
and ec.data_cancellazione is null
;

if tot_imp_cec_paf_fatt is null THEN
tot_imp_cec_paf_fatt:=0.0;
end if;

raise notice 'cec tot_imp_cec_paf_fatt:%',tot_imp_cec_paf_fatt; 


tot_cec := tot_imp_cec_no_giust-tot_imp2_no_giust-tot_imp2_giust_integrato +tot_imp2_giust_restituito+tot_imp_cec_fattura+tot_imp_cec_paf_fatt;

/* ========================================> tot_cec => totCEC <============================= */

return;

END;
$function$
;


-- SIAC-8236 Alessandro T. - FINE


-- SIAC-8152  Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR255_stampa_variazione_Prev_definitive_spese" (
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
  display_error varchar,
  flag_visualizzazione numeric
) AS
$body$
DECLARE

/* 01/07/2021 SIAC-8152.
	Funzione copia della BILR226_stampa_variazione_spese_prev per il nuovo report
    BILR255 che differisce dal BILR266 per il fatto che le variazioni estratte sono
    in stato DEFINITIVO.
*/

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

-- 01/04/2016: il report funziona solo per la previsione
elemTipoCode:='CAP-UP'; -- tipo capitolo previsione

IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
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
flag_visualizzazione = -111;
---------------------------------------------------------------------------------------------------------------------

select fnc_siac_random_user()
into	user_table;

 RTN_MESSAGGIO:='insert tabella siac_rep_mis_pro_tit_mac_riga_anni''.';  


-- carico struttura del bilancio
insert into siac_rep_mis_pro_tit_mac_riga_anni
select * from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id, 
														p_anno, user_table);

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
sql_query=sql_query ||' and		tipologia_stato_var.variazione_stato_tipo_code		 in	(''D'') and 
		tipo_elemento.elem_det_tipo_code					in (''STA'',''SCA'',''STR'')
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
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo >= 0	
        and     tb1.periodo_anno=p_anno_variazione
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo <= 0	
        and     tb2.periodo_anno=p_anno_variazione
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo >= 0	
        and     tb3.periodo_anno=p_anno_variazione
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo <= 0	
        and     tb4.periodo_anno=p_anno_variazione
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo >= 0
        and     tb5.periodo_anno=p_anno_variazione
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo <= 0
        and     tb6.periodo_anno=p_anno_variazione
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table; 
        
        
     RTN_MESSAGGIO:='preparazione file output ''.';  

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
		,COALESCE (vu.elem_id,-111) flag_visualizzazione   ---- cle -nuovo 
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
       left join siac_rep_var_spese vu
     on (	tb.elem_id	=vu.elem_id	
        and  vu.periodo_anno=p_anno_variazione
        and vu.utente = tb.utente ) 
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
	,COALESCE (vu.elem_id,-111) flag_visualizzazione  
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
       left join siac_rep_var_spese vu
     on (	tb.elem_id	=vu.elem_id	
        and  vu.periodo_anno=p_anno_variazione
        and vu.utente = tb.utente ) 
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
flag_visualizzazione  =  classifBilRec.flag_visualizzazione ; 

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
flag_visualizzazione = -111;

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

CREATE OR REPLACE FUNCTION siac."BILR255_stampa_variazione_Prev_definitive_entrate" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar,
  p_anno_variazione varchar
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
  ente_denominazione varchar,
  display_error varchar,
  flag_visualizzazione numeric
) AS
$body$
DECLARE

/* 01/07/2021 SIAC-8152.
	Funzione copia della BILR226_stampa_variazione_entrate_prev per il nuovo report
    BILR255 che differisce dal BILR226 per il fatto che le variazioni estratte sono
    in stato DEFINITIVO.
*/


classifBilRec record;
annoCapImp varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
h_count integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
fase_bilancio varchar;
v_fam_titolotipologiacategoria varchar:='00003';
strApp varchar;
intApp numeric;
sql_query varchar;

BEGIN

annoCapImp:= p_anno; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui

-- 01/04/2016: il report funziona solo per la previsione
elemTipoCode:='CAP-EP'; -- tipo capitolo previsione


IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 intApp = strApp::numeric;
END IF;

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
ente_denominazione ='';
display_error='';
flag_visualizzazione = -111;

select fnc_siac_random_user()
into	user_table;

 RTN_MESSAGGIO:='insert tabella siac_rep_tit_tip_cat_riga_anni''.';  


/* carico la struttura di bilancio completa */
insert into siac_rep_tit_tip_cat_riga_anni
select * from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, 
														p_anno, user_table);


 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep''.';  

insert into siac_rep_cap_eg
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
-- INC000001570761 and	stato_capitolo.elem_stato_code	=	'VA'
and	stato_capitolo.elem_stato_code	in ('VA', 'PR')
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
and	cat_del_capitolo.data_cancellazione	is null;


insert into siac_rep_cap_eg
select null,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente
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
-- INC000001570761 and	stato_capitolo.elem_stato_code	=	'VA'
and	stato_capitolo.elem_stato_code	in ('VA', 'PR')
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and not EXISTS
(
   select 1 from siac_rep_cap_eg x
   where x.elem_id = e.elem_id
   and x.utente=user_table
);


 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep_imp''.';  


INSERT INTO siac_rep_cap_eg_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,   
            sum(capitolo_importi.elem_det_importo)    importo_cap 
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
       -- and	capitolo_imp_periodo.anno in (annoCapImp)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		-- INC000001570761 and	stato_capitolo.elem_stato_code	=	'VA'
		and	stato_capitolo.elem_stato_code	in ('VA', 'PR')
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		--and	cat_del_capitolo.elem_cat_code		=	'STD'
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
    group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,
    capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente;

     RTN_MESSAGGIO:='preparazione tabella importi riga capitolo ''.';  


insert into siac_rep_cap_eg_imp_riga
select  tb1.elem_id,
		tb4.importo		as		residui_attivi,
        tb1.importo 	as 		previsioni_definitive_comp,
        tb2.importo		as		previsioni_definitive_cassa,
        tb1.ente_proprietario,
        user_table utente,
        tb1.periodo_anno
from   
	siac_rep_cap_eg_imp tb1, siac_rep_cap_eg_imp tb2, siac_rep_cap_eg_imp tb4
	where			tb1.elem_id	=	tb2.elem_id	 								and
    				tb1.elem_id	=	tb4.elem_id	 								and												
        			--tb1.periodo_anno 	= annoCapImp		AND	
                    tb1.tipo_imp =	tipoImpComp		        and  
        			tb2.periodo_anno	= tb1.periodo_anno	AND	
                    tb2.tipo_imp = 	tipoImpCassa	        and
                    tb4.periodo_anno	= tb1.periodo_anno	AND	
                    tb4.tipo_imp = 	tipoImpRes		        and
                    tb1.ente_proprietario =	p_ente_prop_id						and
                  	tb2.ente_proprietario	=	tb1.ente_proprietario			and
                    tb4.ente_proprietario	=	tb1.ente_proprietario			and
                    tb1.utente				=	user_table						and
                    tb2.utente				=	tb1.utente						and
                    tb4.utente				=	tb1.utente;
                  
     RTN_MESSAGGIO:='preparazione tabella variazioni''.';  


sql_query='insert into siac_rep_var_entrate
select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),        
        tipo_elemento.elem_det_tipo_code, '''; 
sql_query=sql_query ||user_table||''' utente, 
        testata_variazione.ente_proprietario_id	,
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
        siac_t_bil                  bilancio  
where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
and     anno_eserc.periodo_id                               = bilancio.periodo_id
and     testata_variazione.bil_id                           = bilancio.bil_id 
and     capitolo.bil_id                                     = bilancio.bil_id 
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id  
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id ';
sql_query=sql_query ||' and		tipo_capitolo.elem_tipo_code =	'''||elemTipoCode||'''';
sql_query=sql_query ||' and 	testata_variazione.ente_proprietario_id 	= 	'||p_ente_prop_id;
sql_query=sql_query ||' and		anno_eserc.anno					= 	'''||p_anno||''''; 												
sql_query=sql_query ||' and 	testata_variazione.variazione_num in ('||p_ele_variazioni||') ';  
sql_query=sql_query ||' and		tipologia_stato_var.variazione_stato_tipo_code		 in	(''D'')
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
            anno_importo.anno'  ;    
            
raise notice 'sql_query = %',sql_query;
                    
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
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo >= 0	
        and tb1.periodo_anno=p_anno
        and tb1.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo <= 0	
        and tb2.periodo_anno=p_anno
        and tb2.utente = tb0.utente )
    left join siac_rep_var_entrate tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo >= 0	
        and tb3.periodo_anno=p_anno
        and tb3.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo <= 0	
        and tb4.periodo_anno=p_anno
        and tb4.utente = tb0.utente )
    left join siac_rep_var_entrate tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo >= 0	
        and tb5.periodo_anno=p_anno
        and tb5.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo <= 0
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
        (p_anno::INTEGER + 1)::varchar from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo >= 0	
        and tb1.periodo_anno= (p_anno::INTEGER + 1)::varchar
        and tb1.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo <= 0	
        and tb2.periodo_anno= (p_anno::INTEGER + 1)::varchar
        and tb2.utente = tb0.utente )
    left join siac_rep_var_entrate tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo >= 0	
        and tb3.periodo_anno= (p_anno::INTEGER + 1)::varchar
        and tb3.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo <= 0	
        and tb4.periodo_anno= (p_anno::INTEGER + 1)::varchar
        and tb4.utente = tb0.utente )
    left join siac_rep_var_entrate tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo >= 0	
        and tb5.periodo_anno= (p_anno::INTEGER + 1)::varchar
        and tb5.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo <= 0
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
        (p_anno::INTEGER + 2)::varchar	from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo >= 0	
        and tb1.periodo_anno= (p_anno::INTEGER + 2)::varchar
        and tb1.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo <= 0	
        and tb2.periodo_anno= (p_anno::INTEGER + 2)::varchar
        and tb2.utente = tb0.utente )
    left join siac_rep_var_entrate tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo >= 0	
        and tb3.periodo_anno= (p_anno::INTEGER + 2)::varchar
        and tb3.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo <= 0	
        and tb4.periodo_anno= (p_anno::INTEGER + 2)::varchar
        and tb4.utente = tb0.utente )
    left join siac_rep_var_entrate tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo >= 0	
        and tb5.periodo_anno= (p_anno::INTEGER + 2)::varchar
        and tb5.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo <= 0
        and tb6.periodo_anno= (p_anno::INTEGER + 2)::varchar
        and tb6.utente = tb0.utente 	);

        
     RTN_MESSAGGIO:='preparazione file output ''.';          
  
/* 20/05/2016: aggiunto il controllo se il capitolo ha subito delle variazioni, tramite
	il test su siac_rep_var_entrate_riga x, siac_rep_cap_eg y, siac_r_class_fam_tree z
*/
for classifBilRec in
select 	t_ente.ente_denominazione 		ente_denominazione,
		v1.classif_tipo_desc1    		titoloe_TIPO_DESC,
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
       	tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
        COALESCE (tb1.previsioni_definitive_comp,0)					stanziamento,
    	COALESCE (tb1.previsioni_definitive_cassa,0)			cassa,
        COALESCE (tb1.residui_attivi,0)				residuo,
	   	COALESCE (tb2.variazione_aumento_stanziato,0)			variazione_aumento_stanziato,
		COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)		variazione_diminuzione_stanziato,
    	COALESCE (tb2.variazione_aumento_cassa,0)				variazione_aumento_cassa,
   	 	COALESCE (tb2.variazione_diminuzione_cassa* -1,0)			variazione_diminuzione_cassa,
        COALESCE (tb2.variazione_aumento_residuo,0)				variazione_aumento_residuo,
   	 	COALESCE (tb2.variazione_diminuzione_residuo * -1,0)	variazione_diminuzione_residuo,
        tb1.periodo_anno  anno_riferimento
           ,COALESCE (ve.elem_id,-111) flag_visualizzazione   ---- cle -nuovo 
from  	siac_t_ente_proprietario t_ente,
		siac_rep_tit_tip_cat_riga_anni v1
			left  join siac_rep_cap_eg tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
            left	join    siac_rep_cap_eg_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id 
            		AND tb.utente=tb1.utente
                    and tb.utente=user_table)
            left	join    siac_rep_var_entrate_riga tb2  
            on (tb2.elem_id	=	tb1.elem_id
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table
                    and tb2.periodo_anno=tb1.periodo_anno)
---- cle -nuovo  
       left join siac_rep_var_entrate ve
     on (	tb.elem_id	=ve.elem_id	
        and ve.periodo_anno=p_anno
        and ve.utente = TB.utente ) 
---- fine cle -nuovo  
    where t_ente.ente_proprietario_id=v1.ente_proprietario_id
    and v1.utente = user_table    	
    and  tb1.periodo_anno=p_anno_variazione
   and exists ( select 1 from siac_rep_var_entrate_riga x, siac_rep_cap_eg y, 
                                siac_r_class_fam_tree z
                where x.elem_id= y.elem_id
                 and x.utente=user_table
                 and y.utente=user_table
                 and y.classif_id = z.classif_id
                 and z.classif_id_padre = v1.tipologia_id
            /*  AND (COALESCE(x.variazione_aumento_cassa,0) <>0 OR
                 		COALESCE(x.variazione_aumento_residuo,0) <>0  OR
                        COALESCE(x.variazione_aumento_stanziato,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_cassa,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_residuo,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_stanziato,0) <>0)*/
                        
    )	
    union
    select 	t_ente.ente_denominazione 		ente_denominazione,
		'Titolo'    			titoloe_TIPO_DESC,
       	NULL              		titoloe_ID,
       	'0'            			titoloe_CODE,
       	' '             	titoloe_DESC,
       	'Tipologia'	  			tipologia_TIPO_DESC,
       	null	              	tipologia_ID,
       	'0000000'            	tipologia_CODE,
       	' '           tipologia_DESC,
       	'Categoria'     		categoria_TIPO_DESC,
      	null	              	categoria_ID,
       	'0000000'            	categoria_CODE,
       	' '           categoria_DESC,
    	tb.anno_bilancio    			BIL_ANNO,
       	tb.elem_code     				BIL_ELE_CODE,
       	tb.elem_desc     				BIL_ELE_DESC,
       	tb.elem_code2     				BIL_ELE_CODE2,
       	tb.elem_desc2     				BIL_ELE_DESC2,
       	tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
        COALESCE (tb1.previsioni_definitive_comp,0)					stanziamento,
    	COALESCE (tb1.previsioni_definitive_cassa,0)			cassa,
        COALESCE (tb1.residui_attivi,0)				residuo,
	   	COALESCE (tb2.variazione_aumento_stanziato,0)			variazione_aumento_stanziato,
		COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)		variazione_diminuzione_stanziato,
    	COALESCE (tb2.variazione_aumento_cassa,0)				variazione_aumento_cassa,
   	 	COALESCE (tb2.variazione_diminuzione_cassa* -1,0)			variazione_diminuzione_cassa,
        COALESCE (tb2.variazione_aumento_residuo,0)				variazione_aumento_residuo,
   	 	COALESCE (tb2.variazione_diminuzione_residuo * -1,0)	variazione_diminuzione_residuo,
        tb1.periodo_anno  anno_riferimento
        	,COALESCE (ve.elem_id,-111) flag_visualizzazione  
from  	siac_t_ente_proprietario t_ente,
		 siac_rep_cap_eg tb
            left	join    siac_rep_cap_eg_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id 
            		AND tb.utente=tb1.utente
                    and tb.utente=user_table)
            left	join    siac_rep_var_entrate_riga tb2  
            on (tb2.elem_id	=	tb1.elem_id
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table
                    and tb2.periodo_anno=tb1.periodo_anno) 
 ---- cle -nuovo  
       left join siac_rep_var_entrate ve
     on (	tb.elem_id	=ve.elem_id	
        and ve.periodo_anno=p_anno
        and ve.utente = TB.utente ) 
---- fine cle -nuovo  
    where t_ente.ente_proprietario_id=tb.ente_proprietario_id
    and tb.utente = user_table    	
    and  tb1.periodo_anno=p_anno_variazione
   and tb.classif_id is null
			order by titoloe_CODE,tipologia_CODE,categoria_CODE

loop



---titoloe_tipo_code := classifBilRec.titoloe_tipo_code;
titoloe_TIPO_DESC := classifBilRec.titoloe_TIPO_DESC;
titoloe_CODE := classifBilRec.titoloe_CODE;
titoloe_DESC := classifBilRec.titoloe_DESC;
--------tipologia_tipo_code := classifBilRec.tipologia_tipo_code;
tipologia_tipo_desc := classifBilRec.tipologia_tipo_desc;
tipologia_code := classifBilRec.tipologia_code;
tipologia_desc := classifBilRec.tipologia_desc;
-------categoria_tipo_code := classifBilRec.categoria_tipo_code;
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
ente_denominazione =classifBilRec.ente_denominazione;
flag_visualizzazione  =  classifBilRec.flag_visualizzazione ; 


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
ente_denominazione ='';
flag_visualizzazione = -111;

end loop;

delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;


delete from siac_rep_cap_eg where utente=user_table;

delete from siac_rep_cap_eg_imp where utente=user_table;

delete from siac_rep_cap_eg_imp_riga where utente=user_table;

delete from	siac_rep_var_entrate	where utente=user_table;

delete from siac_rep_var_entrate_riga where utente=user_table; 


raise notice 'fine OK';

exception
	when no_data_found THEN
		raise notice 'Variazioni non trovate' ;
		--return next;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
	when others  THEN
		--raise notice 'errore nella lettura delle variazioni ';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR256_Allegato_8_delibera_variazione_definitive_Prev_ent" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar
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

/* 02/07/2021 SIAC-8152.
	Funzione copia della BILR227_Allegato_7_delibera_variazione_su_entrate_bozza_Prev
    per il nuovo report BILR257 che differisce dal BILR227 per il fatto 
    che le variazioni estratte sono in stato DEFINITIVO.
*/

classifBilRec record;
annoCapImp varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
h_count integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
fase_bilancio varchar;
v_fam_titolotipologiacategoria varchar:='00003';
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
strQuery varchar;

BEGIN

annoCapImp:= p_anno; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui

-- 04/04/2019: il report funziona solo per la previsione
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
display_error:='';


-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 intApp = strApp::numeric;
END IF;

contaParametriParz:=0;
contaParametri:=0;

if p_numero_delibera IS NOT NULL THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_anno_delibera IS NOT NULL AND p_anno_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_tipo_delibera IS NOT NULL AND p_tipo_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;

if contaParametriParz = 1 OR contaParametriParz = 2 then
	display_error:= 'ERRORE NEI PARAMETRI: Specificare tutti i dati relativi al parametro ''Provvedimento di variazione''';
    return next;
    return;
elsif contaParametriParz = 3 THEN -- parametro corretto
	contaParametri := contaParametri + 1;
end if;

contaParametriParz:=0;

if (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
	contaParametri := contaParametri + 1;
end if;


if contaParametri = 0 THEN
	display_error:= 'ERRORE NEI PARAMETRI: Specificare un parametro tra ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
elsif contaParametri = 2 THEN    
	display_error:= 'ERRORE NEI PARAMETRI: Specificare uno solo tra i parametri ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
end if;

select fnc_siac_random_user()
into	user_table;

 RTN_MESSAGGIO:='insert tabella siac_rep_tit_tip_cat_riga_anni''.';  


/* carico la struttura di bilancio completa */
insert into siac_rep_tit_tip_cat_riga_anni
select * from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, 
														p_anno, user_table);

 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep''.';  

insert into siac_rep_cap_eg
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
-- INC000001570761 and	stato_capitolo.elem_stato_code ='VA' 
and	stato_capitolo.elem_stato_code	in	('VA', 'PR')
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
and	cat_del_capitolo.data_cancellazione	is null;


 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep_imp''.';  

/* 18/05/2016: introdotta modifica all'estrazione degli importi dei capitoli.
	Si deve tener conto di eventuali variazioni successive e decrementare 
    l'importo del capitolo.
*/

INSERT INTO siac_rep_cap_eg_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,   
            sum(capitolo_importi.elem_det_importo)    importo_cap 
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
       -- and	capitolo_imp_periodo.anno in (annoCapImp)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		-- INC000001570761 and	stato_capitolo.elem_stato_code ='VA' 
		and	stato_capitolo.elem_stato_code	in	('VA', 'PR')
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code		=	'STD'
        -- 13/02/2017: aggiunto filtro su anno competenza e sugli importi
        and capitolo_imp_periodo.anno =	p_anno_competenza					
        and	capitolo_imp_tipo.elem_det_tipo_code in ('STA','SCA','STR') 		
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
    group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,
    capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente;

     RTN_MESSAGGIO:='preparazione tabella importi riga capitolo ''.';  


insert into siac_rep_cap_eg_imp_riga
select  tb1.elem_id,
		tb4.importo		as		residui_attivi,
        tb1.importo 	as 		previsioni_definitive_comp,
        tb2.importo		as		previsioni_definitive_cassa,
        tb1.ente_proprietario,
        user_table utente,
        tb1.periodo_anno
from   
	siac_rep_cap_eg_imp tb1, siac_rep_cap_eg_imp tb2, siac_rep_cap_eg_imp tb4
	where			tb1.elem_id	=	tb2.elem_id	 								and
    				tb1.elem_id	=	tb4.elem_id	 								and												
        			--tb1.periodo_anno 	= annoCapImp		AND	
                    tb1.tipo_imp =	tipoImpComp		        and  
        			tb2.periodo_anno	= tb1.periodo_anno	AND	
                    tb2.tipo_imp = 	tipoImpCassa	        and
                    tb4.periodo_anno	= tb1.periodo_anno	AND	
                    tb4.tipo_imp = 	tipoImpRes		        and
                    tb1.ente_proprietario =	p_ente_prop_id						and
                  	tb2.ente_proprietario	=	tb1.ente_proprietario			and
                    tb4.ente_proprietario	=	tb1.ente_proprietario			and
                    tb1.utente				=	user_table						and
                    tb2.utente				=	tb1.utente						and
                    tb4.utente				=	tb1.utente;
                  
     RTN_MESSAGGIO:='preparazione tabella variazioni''.';  


--SIAC-6163: 16/05/2018.
-- la query cambia a seconda del tipo parametro: atto/numeri di variazioni.
if p_numero_delibera IS NOT NULL THEN
  insert into siac_rep_var_entrate            
  select	dettaglio_variazione.elem_id,
          sum(dettaglio_variazione.elem_det_importo),
          tipo_elemento.elem_det_tipo_code, 
          user_table utente,
          atto.ente_proprietario_id	,
          anno_importo.anno	      	
  from 	siac_t_atto_amm 			atto,
          siac_d_atto_amm_tipo		tipo_atto,
          siac_r_atto_amm_stato 		r_atto_stato,
          siac_d_atto_amm_stato 		stato_atto,
          siac_r_variazione_stato		r_variazione_stato,
          siac_t_variazione 			testata_variazione,
          siac_d_variazione_tipo		tipologia_variazione,
          siac_d_variazione_stato 	tipologia_stato_var,
          siac_t_bil_elem_det_var 	dettaglio_variazione,
          siac_t_bil_elem				capitolo,
          siac_d_bil_elem_tipo 		tipo_capitolo,
          siac_d_bil_elem_det_tipo	tipo_elemento,
          siac_t_periodo 				anno_eserc ,
          siac_t_periodo              anno_importo,
          siac_t_bil                  bilancio  
  where 	atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
  and		r_atto_stato.attoamm_id								=	atto.attoamm_id
  and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
  and		( r_variazione_stato.attoamm_id						=	atto.attoamm_id
            or r_variazione_stato.attoamm_id_varbil           =	atto.attoamm_id) 
  and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
  and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
  and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id										
  and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
  and     anno_eserc.periodo_id                               = bilancio.periodo_id
  and     testata_variazione.bil_id                           = bilancio.bil_id 
  and     capitolo.bil_id                                     = bilancio.bil_id  
  and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
  and		dettaglio_variazione.elem_id						=	capitolo.elem_id
  and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
  and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
  and 		atto.ente_proprietario_id 							= 	p_ente_prop_id
  and		anno_eserc.anno										= 	p_anno	
  and		atto.attoamm_numero 								= 	p_numero_delibera
  and		atto.attoamm_anno									=	p_anno_delibera
  and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera 
  and     	anno_importo.anno                                   =   p_anno_competenza--anno competenza			
  and		tipologia_stato_var.variazione_stato_tipo_code		 in	('D')
  and		tipo_capitolo.elem_tipo_code						=	elemTipoCode
  and		tipo_elemento.elem_det_tipo_code					in ('STA','SCA','STR')
  and		atto.data_cancellazione						is null
  and		tipo_atto.data_cancellazione				is null
  and		r_atto_stato.data_cancellazione				is null
  and		stato_atto.data_cancellazione				is null
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
              atto.ente_proprietario_id,
              anno_importo.anno	  ;       
else --specificati i numeri di variazione.
	strQuery:='
	insert into siac_rep_var_entrate 
    select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),
        tipo_elemento.elem_det_tipo_code, 
        '''||user_table||''' utente,
        testata_variazione.ente_proprietario_id	,
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
        siac_t_bil                  bilancio  
where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id										
and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
and     anno_eserc.periodo_id                               = bilancio.periodo_id
and     testata_variazione.bil_id                           = bilancio.bil_id 
and     capitolo.bil_id                                     = bilancio.bil_id  
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
and 	testata_variazione.ente_proprietario_id 			= 	'||p_ente_prop_id||'
and		anno_eserc.anno										= 	'''||p_anno||'''
and 	testata_variazione.variazione_num					in ('||p_ele_variazioni||')
and     anno_importo.anno                                   =   '''||p_anno_competenza||'''	--anno variazione				
and		tipologia_stato_var.variazione_stato_tipo_code		 in	(''D'')
and		tipo_capitolo.elem_tipo_code						=	'''||elemTipoCode||'''
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
            anno_importo.anno	  ';
raise notice 'query: %', strQuery;      

execute  strQuery;     
end if;                   


    
     RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  

--/13/02/2017 : e'  rimasto solo il filtro su anno_competenza
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
        p_anno_competenza
from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and tb1.periodo_anno=p_anno_competenza
        and tb1.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and tb2.periodo_anno=p_anno_competenza
        and tb2.utente = tb0.utente )
    left join siac_rep_var_entrate tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and tb3.periodo_anno=p_anno_competenza
        and tb3.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and tb4.periodo_anno=p_anno_competenza
        and tb4.utente = tb0.utente )
    left join siac_rep_var_entrate tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
        and tb5.periodo_anno=p_anno_competenza
        and tb5.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and tb6.periodo_anno=p_anno_competenza
        and tb6.utente = tb0.utente 	);
 
        
     RTN_MESSAGGIO:='preparazione file output ''.';          
  
/* 20/05/2016: aggiunto il controllo se il capitolo ha subito delle variazioni, tramite
	il test su siac_rep_var_entrate_riga x, siac_rep_cap_eg y, siac_r_class_fam_tree z
*/
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
       	tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
        COALESCE (tb1.previsioni_definitive_comp,0)					stanziamento,
    	COALESCE (tb1.previsioni_definitive_cassa,0)			cassa,
        COALESCE (tb1.residui_attivi,0)				residuo,
	   	COALESCE (tb2.variazione_aumento_stanziato,0)			variazione_aumento_stanziato,
		COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)		variazione_diminuzione_stanziato,
    	COALESCE (tb2.variazione_aumento_cassa,0)				variazione_aumento_cassa,
   	 	COALESCE (tb2.variazione_diminuzione_cassa* -1,0)			variazione_diminuzione_cassa,
        COALESCE (tb2.variazione_aumento_residuo,0)				variazione_aumento_residuo,
   	 	COALESCE (tb2.variazione_diminuzione_residuo * -1,0)	variazione_diminuzione_residuo,
        tb1.periodo_anno  anno_riferimento
from  	siac_rep_tit_tip_cat_riga_anni v1
			  join siac_rep_cap_eg tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
            left	join    siac_rep_cap_eg_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id 
            		AND tb.utente=tb1.utente
                    and tb.utente=user_table)
            left	join    siac_rep_var_entrate_riga tb2  
            on (tb2.elem_id	=	tb1.elem_id
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table
                    and tb2.periodo_anno=tb1.periodo_anno) 
    where v1.utente = user_table
   and exists ( select 1 from siac_rep_var_entrate_riga x, siac_rep_cap_eg y, 
                                siac_r_class_fam_tree z
                where x.elem_id= y.elem_id
                 and x.utente=user_table
                 and y.utente=user_table
                 and y.classif_id = z.classif_id
                 and z.classif_id_padre = v1.tipologia_id)	
			order by titoloe_CODE,tipologia_CODE,categoria_CODE
loop



---titoloe_tipo_code := classifBilRec.titoloe_tipo_code;
titoloe_TIPO_DESC := classifBilRec.titoloe_TIPO_DESC;
titoloe_CODE := classifBilRec.titoloe_CODE;
titoloe_DESC := classifBilRec.titoloe_DESC;
--------tipologia_tipo_code := classifBilRec.tipologia_tipo_code;
tipologia_tipo_desc := classifBilRec.tipologia_tipo_desc;
tipologia_code := classifBilRec.tipologia_code;
tipologia_desc := classifBilRec.tipologia_desc;
-------categoria_tipo_code := classifBilRec.categoria_tipo_code;
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

delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;

delete from siac_rep_cap_eg where utente=user_table;

delete from siac_rep_cap_eg_imp where utente=user_table;

delete from siac_rep_cap_eg_imp_riga where utente=user_table;

delete from	siac_rep_var_entrate	where utente=user_table;

delete from siac_rep_var_entrate_riga where utente=user_table; 


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
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

CREATE OR REPLACE FUNCTION siac."BILR256_Allegato_8_delibera_variazione_definitive_Prev_variab" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar
)
RETURNS TABLE (
  id_capitolo integer,
  tipologia_capitolo varchar,
  stanziato numeric,
  variazione_aumento numeric,
  variazione_diminuzione numeric,
  anno_riferimento varchar,
  display_error varchar
) AS
$body$
DECLARE

/* 02/07/2021 SIAC-8152.
	Funzione copia della BILR227_Allegato_7_delibera_variazione_variabili_bozza_Prev
    per il nuovo report BILR257 che differisce dal BILR227 per il fatto 
    che le variazioni estratte sono in stato DEFINITIVO.
*/

classifBilRec record;


annoCapImp varchar;
tipoAvanzo varchar;
tipoDisavanzo varchar;
tipoFpvcc varchar;
tipoFpvsc varchar;
elemTipoCodeE varchar;
elemTipoCodeS varchar;
h_count integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
fase_bilancio varchar;
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
strQuery varchar;
tipoFci varchar;

BEGIN

annoCapImp:= p_anno; 

tipoAvanzo='AAM';
tipoDisavanzo='DAM';
tipoFpvcc='FPVCC';
tipoFpvsc='FPVSC';
tipoFci='FCI';

-- 04/04/2019: il report funziona solo per la previsione
elemTipoCodeE:='CAP-EP'; -- tipo capitolo previsione
elemTipoCodeS:='CAP-UP'; -- tipo capitolo previsione

id_capitolo=0;
tipologia_capitolo='';
stanziato=0;
variazione_aumento=0;
variazione_diminuzione=0;
anno_riferimento='';
display_error:='';

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 intApp = strApp::numeric;
END IF;

contaParametriParz:=0;
contaParametri:=0;

if p_numero_delibera IS NOT NULL THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_anno_delibera IS NOT NULL AND p_anno_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_tipo_delibera IS NOT NULL AND p_tipo_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;

if contaParametriParz = 1 OR contaParametriParz = 2 then
	display_error:= 'ERRORE NEI PARAMETRI: Specificare tutti i dati relativi al parametro ''Provvedimento di variazione''';
    return next;
    return;
elsif contaParametriParz = 3 THEN -- parametro corretto
	contaParametri := contaParametri + 1;
end if;

contaParametriParz:=0;

if (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
	contaParametri := contaParametri + 1;
end if;


if contaParametri = 0 THEN
	display_error:= 'ERRORE NEI PARAMETRI: Specificare un parametro tra ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
elsif contaParametri = 2 THEN    
	display_error:= 'ERRORE NEI PARAMETRI: Specificare uno solo tra i parametri ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
end if;


select fnc_siac_random_user()
into	user_table;

 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep''.';  

insert into siac_rep_cap_eg
select null,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente
 from 	siac_t_bil_elem e,
        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code 	in (elemTipoCodeE,elemTipoCodeS)
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
-- INC000001570761 and	stato_capitolo.elem_stato_code		=	'VA'	
and	stato_capitolo.elem_stato_code		in ('VA', 'PR')
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
--28/06/2021 SIAC-8139
--Aggiunto tipoFci
and	cat_del_capitolo.elem_cat_code	in (tipoAvanzo,tipoDisavanzo,
	tipoFpvcc,tipoFpvsc,tipoFci)
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null;


 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep_imp''.';  

insert into siac_rep_cap_eg_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            cat_del_capitolo.elem_cat_code			tipo_imp,
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
        and	anno_eserc.anno						= 	p_anno 												
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		in (elemTipoCodeE,elemTipoCodeS)
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id
        and	capitolo_imp_tipo.elem_det_tipo_code	=	'STA' 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        --and	capitolo_imp_periodo.anno in (annoCapImp)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		-- INC000001570761 and	stato_capitolo.elem_stato_code		=	'VA'	
        and	stato_capitolo.elem_stato_code		in ('VA', 'PR')
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
            --28/06/2021 SIAC-8139
            --Aggiunto tipoFci        
		and	cat_del_capitolo.elem_cat_code		in (tipoAvanzo,tipoDisavanzo,tipoFpvcc,tipoFpvsc,tipoFci)	
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
    group by capitolo_importi.elem_id,cat_del_capitolo.elem_cat_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente;
   
     RTN_MESSAGGIO:='preparazione tabella importi variazioni ''.';  

            
--SIAC-6163: 16/05/2018.
-- la query cambia a seconda del tipo parametro: atto/numeri di variazioni.
if p_numero_delibera IS NOT NULL THEN
  insert into siac_rep_var_entrate
	(elem_id, importo, utente, ente_proprietario, periodo_anno)
  select	dettaglio_variazione.elem_id,
          sum(dettaglio_variazione.elem_det_importo), -- 30.08.2017 siac-5203 Sofia - aggiunto sum
          --------cat_del_capitolo.elem_cat_code,     -- 30.08.2017 siac-5203 Sofia - commentato
          user_table utente,
          atto.ente_proprietario_id,
          anno_importo.anno	      	
  from 	siac_t_atto_amm 			atto,
          siac_d_atto_amm_tipo		tipo_atto,
          siac_r_atto_amm_stato 		r_atto_stato,
          siac_d_atto_amm_stato 		stato_atto,
          siac_r_variazione_stato		r_variazione_stato,
          siac_t_variazione 			testata_variazione,
          siac_d_variazione_tipo		tipologia_variazione,
          siac_d_variazione_stato 	tipologia_stato_var,
          siac_t_bil_elem_det_var 	dettaglio_variazione,
          siac_t_bil_elem				capitolo,
          siac_d_bil_elem_tipo 		tipo_capitolo,
          siac_d_bil_elem_det_tipo	tipo_elemento,
          siac_d_bil_elem_categoria 	cat_del_capitolo, 
          siac_r_bil_elem_categoria 	r_cat_capitolo,
          siac_t_periodo 				anno_eserc,
          siac_t_periodo              anno_importo ,
          siac_t_bil                  bilancio  
  where 	atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
  and		r_atto_stato.attoamm_id								=	atto.attoamm_id
  and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
  and		( r_variazione_stato.attoamm_id						=	atto.attoamm_id or
            r_variazione_stato.attoamm_id_varbil				=	atto.attoamm_id)
  and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
  and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
  and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id			
  and     anno_eserc.periodo_id                               = bilancio.periodo_id
  and     testata_variazione.bil_id                           = bilancio.bil_id 
  and     capitolo.bil_id                                     = bilancio.bil_id 
  and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
  and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
  and		dettaglio_variazione.elem_id						=	capitolo.elem_id
  and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
  and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
  and		capitolo.elem_id									=	r_cat_capitolo.elem_id
  and		r_cat_capitolo.elem_cat_id							=	cat_del_capitolo.elem_cat_id
  and		atto.ente_proprietario_id 							= 	p_ente_prop_id
  and		anno_eserc.anno										= 	p_anno 		
  and		atto.attoamm_numero 								= 	p_numero_delibera
  and		atto.attoamm_anno									=	p_anno_delibera
  and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera
  and		tipologia_stato_var.variazione_stato_tipo_code		in	('D')										
  and     anno_importo.anno                                   =   p_anno_competenza					
  and		tipo_capitolo.elem_tipo_code						in (elemTipoCodeE,elemTipoCodeS)
  and		tipo_elemento.elem_det_tipo_code					= 'STA'
    --28/06/2021 SIAC-8139
    --Aggiunto tipoFci  
  and		cat_del_capitolo.elem_cat_code	in (tipoAvanzo,tipoDisavanzo,
  		tipoFpvcc,tipoFpvsc,tipoFci)	
  and		atto.data_cancellazione						is null
  and		tipo_atto.data_cancellazione				is null
  and		r_atto_stato.data_cancellazione				is null
  and		stato_atto.data_cancellazione				is null
  and		r_variazione_stato.data_cancellazione		is null
  and		testata_variazione.data_cancellazione		is null
  and		tipologia_variazione.data_cancellazione		is null
  and		tipologia_stato_var.data_cancellazione		is null
  and 	dettaglio_variazione.data_cancellazione		is null
  and 	capitolo.data_cancellazione					is null
  and		tipo_capitolo.data_cancellazione			is null
  and		tipo_elemento.data_cancellazione			is null
  and		cat_del_capitolo.data_cancellazione			is null 
  and     r_cat_capitolo.data_cancellazione			is null
  group by 	dettaglio_variazione.elem_id, -- -- 30.08.2017 siac-5203 Sofia aggiunto group by per sum
              utente,
              atto.ente_proprietario_id,
              anno_importo.anno;
else
	strQuery:='
    	insert into siac_rep_var_entrate
	(elem_id, importo, utente, ente_proprietario, periodo_anno)
          select	dettaglio_variazione.elem_id,
          sum(dettaglio_variazione.elem_det_importo),
          '''||user_table||''' utente,
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
          siac_d_bil_elem_categoria 	cat_del_capitolo, 
          siac_r_bil_elem_categoria 	r_cat_capitolo,
          siac_t_periodo 				anno_eserc,
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
  and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
  and		capitolo.elem_id									=	r_cat_capitolo.elem_id
  and		r_cat_capitolo.elem_cat_id							=	cat_del_capitolo.elem_cat_id
  and		testata_variazione.ente_proprietario_id 			= 	'||p_ente_prop_id||'
  and 	testata_variazione.variazione_num 						in   ('||p_ele_variazioni||')
  and		anno_eserc.anno										= 	'''||p_anno||''' 		
  and		tipologia_stato_var.variazione_stato_tipo_code		in	(''D'')										
  and     anno_importo.anno                                   =   '''||p_anno_competenza||'''					
  and		tipo_capitolo.elem_tipo_code						in ('''||elemTipoCodeE||''','''||elemTipoCodeS||''')
  and		tipo_elemento.elem_det_tipo_code					= ''STA''
    --28/06/2021 SIAC-8139
    --Aggiunto tipoFci    
  and		cat_del_capitolo.elem_cat_code						in ('''||tipoAvanzo||''','''||tipoDisavanzo||''','''||tipoFpvcc||''','''||tipoFpvsc||''','''||tipoFci||''')	
  and		r_variazione_stato.data_cancellazione		is null
  and		testata_variazione.data_cancellazione		is null
  and		tipologia_variazione.data_cancellazione		is null
  and		tipologia_stato_var.data_cancellazione		is null
  and 	dettaglio_variazione.data_cancellazione		is null
  and 	capitolo.data_cancellazione					is null
  and		tipo_capitolo.data_cancellazione			is null
  and		tipo_elemento.data_cancellazione			is null
  and		cat_del_capitolo.data_cancellazione			is null 
  and     r_cat_capitolo.data_cancellazione			is null
  group by 	dettaglio_variazione.elem_id, 
              utente,
              testata_variazione.ente_proprietario_id,
              anno_importo.anno'; 

raise notice 'strQuery = %', strQuery;

execute strQuery;                    
end if;                  	                          
    
     RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  

insert into siac_rep_var_entrate_riga
select  tb0.elem_id,       
		tb1.importo        as 		variazione_aumento_stanziato,
        tb2.importo        as 		variazione_diminuzione_stanziato,
        0,
        0,
        0,
        0,
        user_table utente,
        p_ente_prop_id,
        p_anno
from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
        --and tb1.tipologia  	= 'STA'	
        and 	tb1.importo > 0	
        and     tb1.periodo_anno=p_anno
        and     tb1.utente = tb0.utente
         ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	--and tb2.tipologia  	= 'STA'	
        AND	tb2.importo < 0	
        and tb2.periodo_anno =p_anno 
         and     tb2.utente = tb0.utente)
    where  tb0.utente = user_table 
  union 
  select  tb0.elem_id,       
		tb1.importo        as 		variazione_aumento_stanziato,
        tb2.importo        as 		variazione_diminuzione_stanziato,
        0,
        0,
        0,
        0,
        user_table utente,
        p_ente_prop_id,
        (p_anno::INTEGER + 1)::varchar
    from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
        --and tb1.tipologia  	= 'STA'	
        and 	tb1.importo > 0	
        and     tb1.periodo_anno=(p_anno::INTEGER + 1)::varchar
        and     tb1.utente = tb0.utente
         ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	--and tb2.tipologia  	= 'STA'	
        AND	tb2.importo < 0	
        and tb2.periodo_anno =(p_anno::INTEGER + 1)::varchar 
         and     tb2.utente = tb0.utente)
    where  tb0.utente = user_table 
  union 
  select  tb0.elem_id,       
		tb1.importo        as 		variazione_aumento_stanziato,
        tb2.importo        as 		variazione_diminuzione_stanziato,
        0,
        0,
        0,
        0,
        user_table utente,
        p_ente_prop_id,
        (p_anno::INTEGER + 2)::varchar
    from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
        --and tb1.tipologia  	= 'STA'	
        and 	tb1.importo > 0	
        and     tb1.periodo_anno=(p_anno::INTEGER + 2)::varchar
        and     tb1.utente = tb0.utente
         ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	--and tb2.tipologia  	= 'STA'	
        AND	tb2.importo < 0	
        and tb2.periodo_anno =(p_anno::INTEGER + 2)::varchar 
         and     tb2.utente = tb0.utente)
    where  tb0.utente = user_table 
     ;

     RTN_MESSAGGIO:='preparazione file output ''.';          

for classifBilRec in
select 	tb1.elem_id   		 											id_capitolo,
       	tb1.tipo_imp    												tipologia_capitolo,
       	tb1.importo     												stanziato,
       	COALESCE (tb2.variazione_aumento_stanziato,0)     				variazione_aumento,
       	COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)			variazione_diminuzione,
        tb1.periodo_anno                                                anno_riferimento          
from  	siac_rep_cap_eg_imp tb1  
            left	join    siac_rep_var_entrate_riga tb2  
            on (tb2.elem_id	=	tb1.elem_id
                    and tb1.periodo_anno=tb2.periodo_anno
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table) 
    where tb1.utente = user_table

loop

id_capitolo := classifBilRec.id_capitolo;
tipologia_capitolo := classifBilRec.tipologia_capitolo;
stanziato := classifBilRec.stanziato;

variazione_aumento := classifBilRec.variazione_aumento;
variazione_diminuzione := classifBilRec.variazione_diminuzione;
anno_riferimento := classifBilRec.anno_riferimento;

return next;

end loop;

return next;

delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;
delete from siac_rep_cap_eg where utente=user_table;
delete from siac_rep_cap_eg_imp where utente=user_table;
delete from siac_rep_cap_eg_imp_riga where utente=user_table;
delete from	siac_rep_var_entrate	where utente=user_table;
delete from siac_rep_var_entrate_riga where utente=user_table; 


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
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

CREATE OR REPLACE FUNCTION siac."BILR256_Allegato_8_delibera_variazione_definitive_Prev_spese" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar
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

/* 02/07/2021 SIAC-8152.
	Funzione copia della BILR227_Allegato_7_delibera_variazione_su_spese_bozza_Prev
    per il nuovo report BILR257 che differisce dal BILR227 per il fatto 
    che le variazioni estratte sono in stato DEFINITIVO.
*/

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
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
strQuery varchar;


BEGIN

annoCapImp:= p_anno; 
annocapimp2:=(p_anno::INTEGER + 1)::varchar;
annocapimp3:=(p_anno::INTEGER + 2)::varchar;

raise notice '%', annoCapImp;


TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui

-- 04/04/2019: il report funziona solo per la previsione
elemTipoCode:='CAP-UP'; -- tipo capitolo previsione

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
display_error:='';


-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 intApp = strApp::numeric;
END IF;

contaParametriParz:=0;
contaParametri:=0;

if p_numero_delibera IS NOT NULL THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_anno_delibera IS NOT NULL AND p_anno_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_tipo_delibera IS NOT NULL AND p_tipo_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;

if contaParametriParz = 1 OR contaParametriParz = 2 then
	display_error:= 'ERRORE NEI PARAMETRI: Specificare tutti i dati relativi al parametro ''Provvedimento di variazione''';
    return next;
    return;
elsif contaParametriParz = 3 THEN -- parametro corretto
	contaParametri := contaParametri + 1;
end if;

contaParametriParz:=0;

if (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
	contaParametri := contaParametri + 1;
end if;


if contaParametri = 0 THEN
	display_error:= 'ERRORE NEI PARAMETRI: Specificare un parametro tra ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
elsif contaParametri = 2 THEN    
	display_error:= 'ERRORE NEI PARAMETRI: Specificare uno solo tra i parametri ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
end if;

select fnc_siac_random_user()
into	user_table;

 RTN_MESSAGGIO:='insert tabella siac_rep_mis_pro_tit_mac_riga_anni''.'; 
 
 -- carico struttura del bilancio
insert into siac_rep_mis_pro_tit_mac_riga_anni
select * from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id, 
													p_anno, user_table);

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
    stato_capitolo.elem_stato_code		in ('VA', 'PR')						and			
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

  

RTN_MESSAGGIO:='insert tabella siac_rep_cap_ug_imp standard''.';  


/* Si deve tener conto di eventuali variazioni successive e decrementare 
   l'importo del capitolo.
*/

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
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code		in ('VA', 'PR')								
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')	
        and capitolo_imp_periodo.anno =	p_anno_competenza					
        and	capitolo_imp_tipo.elem_det_tipo_code in ('STA','SCA','STR') 		
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
        		--tb1.periodo_anno 		= annoCapImp		AND	 
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
     
-- la query cambia a seconda del tipo parametro: atto/numeri di variazioni.
if p_numero_delibera IS NOT NULL THEN
insert into siac_rep_var_spese            
  select	dettaglio_variazione.elem_id,
          sum(dettaglio_variazione.elem_det_importo),
          tipo_elemento.elem_det_tipo_code, 
          user_table utente,
          atto.ente_proprietario_id	,
          anno_importo.anno	      	
  from 	siac_t_atto_amm 			atto,
          siac_d_atto_amm_tipo		tipo_atto,
          siac_r_atto_amm_stato 		r_atto_stato,
          siac_d_atto_amm_stato 		stato_atto,
          siac_r_variazione_stato		r_variazione_stato,
          siac_t_variazione 			testata_variazione,
          siac_d_variazione_tipo		tipologia_variazione,
          siac_d_variazione_stato 	tipologia_stato_var,
          siac_t_bil_elem_det_var 	dettaglio_variazione,
          siac_t_bil_elem				capitolo,
          siac_d_bil_elem_tipo 		tipo_capitolo,
          siac_d_bil_elem_det_tipo	tipo_elemento,
          siac_t_periodo 				anno_eserc ,
          siac_t_periodo              anno_importo,
          siac_t_bil                  bilancio  
  where 	atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
  and		r_atto_stato.attoamm_id								=	atto.attoamm_id
  and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
  and		( r_variazione_stato.attoamm_id						=	atto.attoamm_id
            or r_variazione_stato.attoamm_id_varbil           =	atto.attoamm_id) 
  and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
  and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
  and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id										
  and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
  and     anno_eserc.periodo_id                               = bilancio.periodo_id
  and     testata_variazione.bil_id                           = bilancio.bil_id 
  and     capitolo.bil_id                                     = bilancio.bil_id  
  and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
  and		dettaglio_variazione.elem_id						=	capitolo.elem_id
  and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
  and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
  and 	atto.ente_proprietario_id 							= 	p_ente_prop_id
  and		anno_eserc.anno										= 	p_anno	
  and		atto.attoamm_numero 								= 	p_numero_delibera
  and		atto.attoamm_anno									=	p_anno_delibera
  and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera
  and     anno_importo.anno                                   =   p_anno_competenza		
  and		tipologia_stato_var.variazione_stato_tipo_code		 in	('D')
  and		tipo_capitolo.elem_tipo_code						=	elemTipoCode
  and		tipo_elemento.elem_det_tipo_code					in ('STA','SCA','STR')
  and		atto.data_cancellazione						is null
  and		tipo_atto.data_cancellazione				is null
  and		r_atto_stato.data_cancellazione				is null
  and		stato_atto.data_cancellazione				is null
  and		r_variazione_stato.data_cancellazione		is null
  and		testata_variazione.data_cancellazione		is null
  and		tipologia_variazione.data_cancellazione		is null
  and		tipologia_stato_var.data_cancellazione		is null
  and 		dettaglio_variazione.data_cancellazione		is null
  and 		capitolo.data_cancellazione					is null
  and		tipo_capitolo.data_cancellazione			is null
  and		tipo_elemento.data_cancellazione			is null
  group by 	dettaglio_variazione.elem_id,
              tipo_elemento.elem_det_tipo_code, 
              utente,
              atto.ente_proprietario_id,
              anno_importo.anno	  ;       
else --specificati i numeri di variazione.
	strQuery:='
	insert into siac_rep_var_spese 
    select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),
        tipo_elemento.elem_det_tipo_code, 
        '''||user_table||''' utente,
        testata_variazione.ente_proprietario_id	,
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
        siac_t_bil                  bilancio  
where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id										
and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
and     anno_eserc.periodo_id                               = bilancio.periodo_id
and     testata_variazione.bil_id                           = bilancio.bil_id 
and     capitolo.bil_id                                     = bilancio.bil_id  
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
and 	testata_variazione.ente_proprietario_id 			= 	'||p_ente_prop_id||'
and		anno_eserc.anno										= 	'''||p_anno||'''
and 	testata_variazione.variazione_num					in ('||p_ele_variazioni||')
and     anno_importo.anno                                   =   '''||p_anno_competenza||'''				
and		tipologia_stato_var.variazione_stato_tipo_code		 in	(''D'')
and		tipo_capitolo.elem_tipo_code						=	'''||elemTipoCode||'''
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
            anno_importo.anno	  ';
raise notice 'query: %', strQuery;      

execute  strQuery;     
end if;                               
        

--/13/02/2017 : e'  rimasto solo il filtro su anno_competenza
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
        p_anno_competenza 
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=p_anno_competenza
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=p_anno_competenza
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=p_anno_competenza
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=p_anno_competenza
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=p_anno_competenza
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=p_anno_competenza
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  ; 
        
        
     RTN_MESSAGGIO:='preparazione file output ''.';  
         
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
			join siac_rep_cap_ug tb
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
    and exists ( select 1 from siac_rep_var_spese_riga x, siac_rep_cap_ug y, 
                                siac_r_class_fam_tree z
                where x.elem_id= y.elem_id
                 and x.utente=user_table
                 and y.utente=user_table
                 and y.macroaggregato_id = z.classif_id
                 and z.classif_id_padre = v1.titusc_id
                 and y.programma_id=v1.programma_id                                     
    )	
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
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
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

-- SIAC-8152  Maurizio - FINE 

-- SIAC-8277 Sofia 06072021 inizio 
drop function if exists 
siac.fnc_pagopa_t_elaborazione_riconc_esegui 
(
  filepagopaelabid integer,
  annobilancioelab integer,
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

CREATE OR REPLACE FUNCTION siac.fnc_pagopa_t_elaborazione_riconc_esegui(filepagopaelabid integer, annobilancioelab integer, enteproprietarioid integer, loginoperazione character varying, dataelaborazione timestamp without time zone, OUT codicerisultato integer, OUT messaggiorisultato character varying)
 RETURNS record
AS $body$
DECLARE

	strMessaggio VARCHAR(2500):=''; -- 09.10.2019 Sofia
	strMessaggioBck VARCHAR(2500):=''; -- 09.10.2019 Sofia
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
    -- 18.01.2021 Sofia Jira SIAC-7962
    ESERCIZIO_CONSUNTIVO_ST    CONSTANT  varchar :='O'; -- esercizio consuntivo

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


	-- 31.05.2019 siac-6720
	PAGOPA_ERR_41   CONSTANT  varchar :='41';--ESTREMI SOGGETTO NON PRESENTI PER DETTAGLIO
	PAGOPA_ERR_42   CONSTANT  varchar :='42';--DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO NON PRESENTE
	PAGOPA_ERR_43   CONSTANT  varchar :='43';--DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO NON VALIDO
 	PAGOPA_ERR_44   CONSTANT  varchar :='44';--DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO VALIDO NON UNIVOCO COD.FISC.
 	PAGOPA_ERR_45   CONSTANT  varchar :='45';--DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO VALIDO NON UNIVOCO PIVA
 	PAGOPA_ERR_46   CONSTANT  varchar :='46';--DATI RICONCILIAZIONE DETTAGLIO FAT. SENZA IDENTIFICATIVO SOGGETTO ASSOCIATO
 	PAGOPA_ERR_47   CONSTANT  varchar :='47';--ERRORE IN LETTURA IDENTIFICATIVO ATTRIBUTI ACCERTAMENTO
    PAGOPA_ERR_48   CONSTANT  varchar :='48';--TIPO DOCUMENTO NON PRESENTE SU DATI DI RICONCILIAZIONE
    PAGOPA_ERR_49   CONSTANT  varchar :='49';--DETTAGLI NON PRESENTI SU DATI DI RICONCILIAZIONE CON DETT
    PAGOPA_ERR_50   CONSTANT  varchar :='50';--DATI RICONCILIAZIONE DETTAGLIO FAT. PRIVI DI IMPORTO

    -- 22.07.2019 Sofia siac-6963 - inizio
	PAGOPA_ERR_51   CONSTANT  varchar :='51';--DATI RICONCILIAZIONE CON ACCERTAMENTO PRIVO DI SOGGETTO O INESISTENTE

    DOC_STATO_VALIDO    CONSTANT  varchar :='V';
	DOC_TIPO_IPA    CONSTANT  varchar :='IPA';
    --- 12.06.2019 SIAC-6720
    DOC_TIPO_COR    CONSTANT  varchar :='COR';
    DOC_TIPO_FAT    CONSTANT  varchar :='FTV';

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

    --- 12.06.2019 Siac-6720
    docTipoFatId integer:=null;
    docTipoCorId integer:=null;
    docTipoCorNumAutom integer:=null;
    docTipoFatNumAutom integer:=null;
    nProgressivoFat integer:=null;
    nProgressivoCor integer:=null;
    nProgressivoTemp integer:=null;
	isDocIPA boolean:=false;

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

    -- 11.06.2019 SIAC-6720
	numModifica  integer:=null;
    attoAmmId    integer:=null;
    modificaTipoId integer:=null;
    modifId       integer:=null;
    modifStatoId  integer:=null;
    modStatoRId   integer:=Null;

	-- 13.09.2019 Sofia SIAC-7034
    numeroFattura varchar(250):=null;

    fncRec record;
    pagoPaFlussoRec record;
    pagoPaFlussoQuoteRec record;
    elabRec record;

	-- 12.08.2019 Sofia SIAC-6978 - fine
    docIUV varchar(150):=null;
    -- 06.02.2020 Sofia jira siac-7375
    docDataOperazione timestamp:=null;
BEGIN

	strMessaggioFinale:='Elaborazione rinconciliazione PAGOPA per '||
                        'Id. elaborazione filePagoPaElabId='||filePagoPaElabId::varchar||
                        ' AnnoBilancioElab='||annoBilancioElab::varchar||'.';

    strMessaggioLog:='Inizio fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale;
--    raise notice '%',strMessaggioLog;

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
    GET DIAGNOSTICS codResult = ROW_COUNT;
    raise notice '2222%',strMessaggioLog;
    raise notice '2222-codResult- %',codResult;
    codResult:=null;
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
    raise notice '2222strMessaggio  %',strMessaggio;
    raise notice '2222strMessaggio CodResult %',codResult;

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
      strMessaggio:='Verifica esistenza tipo documento='||DOC_TIPO_FAT||'.';
      -- lettura tipodocumento
      select tipo.doc_tipo_id into docTipoFatId
      from siac_d_doc_tipo tipo,siac_d_doc_fam_tipo fam
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.doc_tipo_code=DOC_TIPO_FAT
      and   fam.doc_fam_tipo_id=tipo.doc_fam_tipo_id
      and   fam.doc_fam_tipo_code='E';
      if docTipoFatId is null then
          pagoPaCodeErr:=PAGOPA_ERR_24;
          strErrore:=' Non esistente.';
          codResult:=-1;
          bElabora:=false;
      else
	      select 1 into docTipoFatNumAutom
          from siac_r_doc_tipo_attr rattr,siac_t_attr attr
          where rattr.doc_tipo_id=docTipoFatId
          and   attr.attr_id=rattr.attr_id
          and   attr.attr_code='flagSenzaNumero'
          and   coalesce(rattr.boolean,'N')='S'
          and   rattr.data_cancellazione is null
          and   rattr.validita_fine is null;
      end if;

  end if;

  if codResult is null then
      strMessaggio:='Verifica esistenza tipo documento='||DOC_TIPO_COR||'.';
      -- lettura tipodocumento
      select tipo.doc_tipo_id into docTipoCorId
      from siac_d_doc_tipo tipo,siac_d_doc_fam_tipo fam
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.doc_tipo_code=DOC_TIPO_COR
      and   fam.doc_fam_tipo_id=tipo.doc_fam_tipo_id
      and   fam.doc_fam_tipo_code='E';

      if docTipoCorId is null then
          pagoPaCodeErr:=PAGOPA_ERR_24;
          strErrore:=' Non esistente.';
          codResult:=-1;
          bElabora:=false;
      else
   	      select 1 into docTipoCorNumAutom
          from siac_r_doc_tipo_attr rattr,siac_t_attr attr
          where rattr.doc_tipo_id=docTipoCorId
          and   attr.attr_id=rattr.attr_id
          and   attr.attr_code='flagSenzaNumero'
          and   coalesce(rattr.boolean,'N')='S'
          and   rattr.data_cancellazione is null
          and   rattr.validita_fine is null;

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
        if docStatoValId is null then
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
    raise notice '22229998@@%',strMessaggio;

     select  distinct doc.pagopa_ric_doc_anno_esercizio into annoBilancio
     from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
     where flusso.pagopa_elab_id=filePagoPaElabId
     and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc.pagopa_ric_doc_stato_elab='N'
     and   doc.pagopa_ric_doc_subdoc_id is null
     and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
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
         raise notice '2222@@strErrore%',strErrore;

	end if;


    if codResult is null then
	 strMessaggio:='Gestione scarti di elaborazione. Verifica fase bilancio per elaborazione.';
         raise notice '22229997@@%',strMessaggio;

	 select bil.bil_id, per.periodo_id into bilancioId , periodoId
     from siac_t_bil bil,siac_t_periodo per,
          siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where per.ente_proprietario_id=enteProprietarioid
     and   per.anno::integer=annoBilancio
     and   bil.periodo_id=per.periodo_id
     and   r.bil_id=bil.bil_id
     and   fase.fase_operativa_id=r.fase_operativa_id
     -- 18.01.2021 Sofia Jira SIAC-7962
--     and   fase.fase_operativa_code in (ESERCIZIO_PROVVISORIO_ST,ESERCIZIO_GESTIONE_ST);
     and   fase.fase_operativa_code in (ESERCIZIO_PROVVISORIO_ST,ESERCIZIO_GESTIONE_ST,ESERCIZIO_CONSUNTIVO_ST);
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

   --- 12.06.2019 Sofia SIAC-6720
   if codResult is null and
      (docTipoCorNumAutom is not null or docTipoFatNumAutom is not null ) then
	  strMessaggio:='Gestione scarti di elaborazione. Lettura progressivo doc. siac_t_doc_num ['
                   ||DOC_TIPO_FAT||'-'
                   ||DOC_TIPO_COR
                   ||'] per anno='||annoBilancio::varchar||'.';

      nProgressivoFat:=0;
      nProgressivoCor:=0;
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
             nProgressivoFat,
             tipo.doc_tipo_id,
             clock_timestamp(),
             loginOperazione,
             bil.ente_proprietario_id
      from siac_t_bil bil,siac_d_doc_tipo tipo
      where bil.bil_id=bilancioId
      --and   tipo.doc_tipo_id in (docTipoFatId,docTipoCorId)
      and   tipo.doc_tipo_id in
      (select docTipoCorId doc_tipo_id where  docTipoCorNumAutom is not null
       union
       select docTipoFatId doc_tipo_id where  docTipoFatNumAutom is not null
      )
      and not exists
      (
      select 1
      from siac_t_doc_num num
      where num.ente_proprietario_id=bil.ente_proprietario_id
      and   num.doc_anno::integer=annoBilancio
      and   num.doc_tipo_id=tipo.doc_tipo_id
      and   num.data_cancellazione is null
      and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
      );
      GET DIAGNOSTICS codResult = ROW_COUNT;

	  codResult:=null;
      --if codResult is null then
      if docTipoCorNumAutom is not null then
          select num.doc_numero into codResult
          from siac_t_doc_num num
          where num.ente_proprietario_id=enteProprietarioId
          and   num.doc_anno::integer=annoBilancio
          and   num.doc_tipo_id =docTipoCorId;

          if codResult is not null then
              nProgressivoCor:=codResult;
              codResult:=null;
          else
              pagoPaCodeErr:=PAGOPA_ERR_37;
              strErrore:=' Progressivo non reperito.';
              codResult:=-1;
              bElabora:=false;
          end if;
      end if;

      if docTipoFatNumAutom is not null and codResult is null then
          select num.doc_numero into codResult
          from siac_t_doc_num num
          where num.ente_proprietario_id=enteProprietarioId
          and   num.doc_anno::integer=annoBilancio
          and   num.doc_tipo_id =docTipoFatId;

          if codResult is not null then
              nProgressivoFat:=codResult;
              codResult:=null;
          else
              pagoPaCodeErr:=PAGOPA_ERR_37;
              strErrore:=' Progressivo non reperito.';
              codResult:=-1;
              bElabora:=false;
          end if;
      end if;
--    else codResult:=null;
--    end if;

   end if;

   if codResult is null then
    strMessaggio:='Gestione scarti di elaborazione. Inserimento siac_t_registrounico_doc_num per anno='||annoBilancio::varchar||'.';
    raise notice '22229996@@%',strMessaggio;

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
     raise notice '2222999999@@strMessaggio PAGOPA_ERR_22 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
              login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
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
     --     26.07.2019 Sofia questo controllo causa
     --     nelle update successive il non aggiornamento del motivo di scarto
     --     sulle righe dello stesso flusso ma con motivi diversi
     --     gli step successivi ( update successivi ) lasciano elab='N'
     --     in questo modo il flusso non viene elaborato
     --     in quanto la stessa condizione compare nel query del loop di elaborazione
     --     ma non tutti i dettagli in scarto vengono trattati ed eventualmente associati
     --     a un motivo di scarto
     --     bisogna tenerne conto quando un  flusso non viene elaborato
     --     e non tutti i dettagli hanno un motivo di scarto segnalato
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
--     raise notice '2222@@strMessaggio PAGOPA_ERR_38 %',strMessaggio;
     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
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
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_38
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
--               login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
               login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

   	   from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
	   where  flusso.pagopa_elab_id=filePagoPaElabId
       and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
       and    doc.pagopa_ric_doc_stato_elab='N'
       and    doc.pagopa_ric_doc_subdoc_id is null
       and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
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
       and    err.pagopa_ric_errore_code=PAGOPA_ERR_38
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
--     raise notice '2222@@strMessaggio PAGOPA_ERR_23 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
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

   -- siac-6720 31.05.2019 controlli - inizio


   -- dettagli con codice fiscale non indicato
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_41||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')=''
     and    doc.pagopa_ric_doc_subdoc_id is null
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
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_41
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_41;
        strErrore:=' Estremi soggetto non indicati per dati di dettaglio-fatt.';
     end if;
     codResult:=null;
   end if;

   -- dettagli con codice fiscale indicato
   --  soggetto non esistente
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_42||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    not exists
     (
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     select  1
     from  siac_t_soggetto sog,siac_d_ambito ambito
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   ambito.ambito_id=sog.ambito_id
     and   ambito.ambito_code='AMBITO_FIN'
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     )
     and    not exists
     (
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     select  1
     from  siac_t_soggetto sog,siac_d_ambito ambito
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   ambito.ambito_id=sog.ambito_id
     and   ambito.ambito_code='AMBITO_FIN'
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
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_42
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_42;
        strErrore:=' Soggetto inesistente per dati di dettaglio-fatt. ';
     end if;
     codResult:=null;
   end if;

   -- dettagli con codice fiscale indicato
   --  soggetto esistente ma non valido
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_43||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    not exists
     (
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     select  1
     from  siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato,
           siac_d_ambito ambito
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   rs.soggetto_id=sog.soggetto_id
     and   stato.soggetto_stato_id=rs.soggetto_stato_id
     and   stato.soggetto_stato_code='VALIDO'
     and   ambito.ambito_id=sog.ambito_id
     and   ambito.ambito_code='AMBITO_FIN'
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     and   rs.data_cancellazione is null
     and   rs.validita_fine is null
     )
     and    not exists
     (
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     select  1
     from  siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato,
           siac_d_ambito ambito
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   rs.soggetto_id=sog.soggetto_id
     and   stato.soggetto_stato_id=rs.soggetto_stato_id
     and   stato.soggetto_stato_code='VALIDO'
     and   ambito.ambito_id=sog.ambito_id
     and   ambito.ambito_code='AMBITO_FIN'
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
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
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_43
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_43;
        strErrore:=' Soggetto esistente non VALIDO per dati di dettaglio-fatt. ';
     end if;
     codResult:=null;
   end if;

   -- dettagli con codice fiscale indicato
   --  soggetto esistente valido ma non univoco (diversi soggetti per stesso codice fiscale)
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_44||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_dett=true
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    exists
     (
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     select (case when 1<count(*) then 1 else 0 end)
	 from siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato,
          siac_d_ambito ambito
	 where sog.ente_proprietario_id=enteProprietarioId
	 and   sog.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs.soggetto_id=sog.soggetto_id
	 and   stato.soggetto_stato_id=rs.soggetto_stato_id
	 and   stato.soggetto_stato_code='VALIDO'
     and   ambito.ambito_id=sog.ambito_id
     and   ambito.ambito_code='AMBITO_FIN'
	 and   sog.data_cancellazione is null
	 and   sog.validita_fine is null
	 and   rs.data_cancellazione is null
	 and   rs.validita_fine is null
	 group by sog.codice_fiscale
	 having count(*)>1
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
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_44
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_44;
        strErrore:=' Soggetto esistente VALIDO non univoco (cod.fisc) per dati di dettaglio-fatt. ';
     end if;
     codResult:=null;
   end if;

   --  soggetto esistente valido ma non univoco (diversi soggetti per stessa partita iva)
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_45||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_dett=true
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    exists
     (
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     select (case when 1<count(*) then 1 else 0 end)
	 from siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato,
          siac_d_ambito ambito
	 where sog.ente_proprietario_id=enteProprietarioId
	 and   sog.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs.soggetto_id=sog.soggetto_id
	 and   stato.soggetto_stato_id=rs.soggetto_stato_id
	 and   stato.soggetto_stato_code='VALIDO'
     and   ambito.ambito_id=sog.ambito_id
     and   ambito.ambito_code='AMBITO_FIN'
	 and   sog.data_cancellazione is null
	 and   sog.validita_fine is null
	 and   rs.data_cancellazione is null
	 and   rs.validita_fine is null
	 group by sog.partita_iva
	 having count(*)>1
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
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_45
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_45;
        strErrore:=' Soggetto esistente VALIDO non univoco (p.iva) per dati di dettaglio-fatt. ';
     end if;
     codResult:=null;
   end if;


   -- aggiornare tutti i dettagli con il soggetto_id
   -- (anche il codice del soggetto !! adesso funziona gia' tutto con il codice del soggetto impostato )
   if codResult is null then
 	 strMessaggio:='Aggiornamento dati soggetto su dati di riconciliazione di dettaglio per codice fiscale [pagopa_t_riconciliazione_doc].';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_soggetto_id=sog.soggetto_id,
            pagopa_ric_doc_codice_benef=sog.soggetto_code,
            data_modifica=clock_timestamp()
     from pagopa_t_elaborazione_flusso flusso,siac_t_soggetto sog, siac_r_soggetto_stato rs,siac_d_soggetto_stato stato,
          siac_d_ambito ambito
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_dett=true
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_soggetto_id is null
     and    sog.ente_proprietario_id=enteProprietarioId
	 and    sog.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and    rs.soggetto_id=sog.soggetto_id
	 and    stato.soggetto_stato_id=rs.soggetto_stato_id
	 and    stato.soggetto_stato_code='VALIDO'
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     and   ambito.ambito_id=sog.ambito_id
     and   ambito.ambito_code='AMBITO_FIN'
     and    exists
     (
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     select 1
	 from siac_t_soggetto sog1,siac_r_soggetto_stato rs1,siac_d_ambito ambito1
	 where sog1.ente_proprietario_id=enteProprietarioId
	 and   sog1.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs1.soggetto_id=sog1.soggetto_id
	 and   rs1.soggetto_stato_id=stato.soggetto_stato_id
     and   ambito1.ambito_id=sog1.ambito_id
     and   ambito1.ambito_code='AMBITO_FIN'
	 and   sog1.data_cancellazione is null
	 and   sog1.validita_fine is null
	 and   rs1.data_cancellazione is null
	 and   rs1.validita_fine is null
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
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null
  	 and    sog.data_cancellazione is null
	 and    sog.validita_fine is null
	 and    rs.data_cancellazione is null
	 and    rs.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     codResult:=null;
     strMessaggio:='Aggiornamento dati soggetto su dati di riconciliazione di dettaglio per partita iva [pagopa_t_riconciliazione_doc].';
     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_soggetto_id=sog.soggetto_id,
            pagopa_ric_doc_codice_benef=sog.soggetto_code,
            data_modifica=clock_timestamp()
     from pagopa_t_elaborazione_flusso flusso,siac_t_soggetto sog, siac_r_soggetto_stato rs,siac_d_soggetto_stato stato,
          siac_d_ambito ambito
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_dett=true
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_soggetto_id is null
     and    sog.ente_proprietario_id=enteProprietarioId
	 and    sog.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and    rs.soggetto_id=sog.soggetto_id
	 and    stato.soggetto_stato_id=rs.soggetto_stato_id
	 and    stato.soggetto_stato_code='VALIDO'
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     and    ambito.ambito_id=sog.ambito_id
     and    ambito.ambito_code='AMBITO_FIN'
     and    exists
     (
     select 1
	 from siac_t_soggetto sog1,siac_r_soggetto_stato rs1,siac_d_ambito ambito
	 where sog1.ente_proprietario_id=enteProprietarioId
	 and   sog1.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs1.soggetto_id=sog1.soggetto_id
	 and   rs1.soggetto_stato_id=stato.soggetto_stato_id
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     and   ambito.ambito_id=sog1.ambito_id
     and   ambito.ambito_code='AMBITO_FIN'
	 and   sog1.data_cancellazione is null
	 and   sog1.validita_fine is null
	 and   rs1.data_cancellazione is null
	 and   rs1.validita_fine is null
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
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null
  	 and    sog.data_cancellazione is null
	 and    sog.validita_fine is null
	 and    rs.data_cancellazione is null
	 and    rs.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
     codResult:=null;
   end if;

   --  soggetto_id non aggiornato su dettagli di riconciliazione
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_46||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_soggetto_id is null
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
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_46
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_46;
        strErrore:=' Esistanza  dati di dettaglio-fatt. senza estremi soggetto aggiornato. ';
     end if;
     codResult:=null;
   end if;

   --  importo non valorizzato  su dettagli di riconciliazione
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_50||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_sottovoce_importo,0)=0
     and    doc.pagopa_ric_doc_subdoc_id is null
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
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_50
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_50;
        strErrore:=' Esistanza  dati di dettaglio-fatt. senza importo valorizzato. ';
     end if;
     codResult:=null;
   end if;

   -- siac-6720 31.05.2019 controlli - fine

   -- siac-6720 31.05.2019 controlli commentare il seguente
   -- soggetto indicato non esistente non esistente
   /*if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_34||'.';
     raise notice '2222@@strMessaggio PAGOPA_ERR_34 %',strMessaggio;

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
   end if;*/

   -- struttura amministrativa indicata non esistente indicato non esistente non esistente
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_35||'.';
--     raise notice '2222@@strMessaggio PAGOPA_ERR_35 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
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

   -- 22.07.2019 Sofia siac-6963 - inizio
   -- accertamento indicato per IPA,COR senza soggetto o soggetto  non esistente
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_51||'.';
     raise notice '2222@@strMessaggio PAGOPA_ERR_51 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false
     and    doc.pagopa_ric_doc_flag_dett=false
     and    not exists
     (
      select 1
      from siac_t_movgest mov, siac_d_movgest_tipo tipo,
           siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
           siac_r_movgest_ts_stato rs, siac_d_movgest_stato stato,
           siac_r_movgest_ts_sog rsog,siac_t_soggetto sog
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
      and   rsog.movgest_ts_id=ts.movgest_ts_id
      and   sog.soggetto_id=rsog.soggetto_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   rsog.data_cancellazione is null
      and   rsog.validita_fine is null
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
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_51
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_51;
        strErrore:=' Soggetto non indicato su accertamento o non esistente.';
     end if;
     codResult:=null;
   end if;
   -- 22.07.2019 Sofia siac-6963 - fine

--raise notice '@@@@@@@@@@@@@pagoPaCodeErr   %',pagoPaCodeErr;
--raise notice 'codResult   %',codResult;
  ---  aggiornamento di pagopa_t_riconciliazione a partire da pagopa_t_riconciliazione_doc
  ---  per gli scarti prodotti in questa elaborazione
  if codResult is null then
   strMessaggio:='Gestione scarti di elaborazione. Aggiornamento pagopa_t_riconciliazione da pagopa_t_riconciliazione_doc.';
--   raise notice '2222@@strMessaggio   %',strMessaggio;
--   raise notice '@@@@@@@@@@@@@pagoPaCodeErr   %',pagoPaCodeErr;
   update pagopa_t_riconciliazione ric
   set    pagopa_ric_flusso_stato_elab='X',
  	      pagopa_ric_errore_id=doc.pagopa_ric_errore_id,
          data_modifica=clock_timestamp(),
--          login_operazione=ric.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
          login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

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
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
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
     raise notice 'strMessaggioStrErrore=%',strMessaggio;
	 update pagopa_t_elaborazione elab
     set    data_modifica=clock_timestamp(),
            validita_fine=(case when bElabora=false then clock_timestamp() else null end ),
            pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
            pagopa_elab_errore_id=err.pagopa_ric_errore_id,
		    pagopa_elab_note=substr(upper(strMessaggioFinale||' '||strMessaggio),1,1500) -- 09.10.2019 Sofia
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
            file_pagopa_note=substr(upper(strMessaggioFinale||' '||strMessaggio),1,1500), -- 09.10.2019 Sofia
            login_operazione=substr(loginOperazione||'-'||file.login_operazione,1,200) -- 09.10.2019 Sofia
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
      -- 10.05.2021 Sofia Jira SIAC-8167
      if pagoPaCodeErr=PAGOPA_ERR_7 then
      	codiceRisultato:=0;
      else
        codiceRisultato:=-1;
      end if;

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

--  raise notice 'strMessaggio=%',strMessaggio;
  for pagoPaFlussoRec in
  (
   with
   pagopa_sogg as
   (
   with
   pagopa as
   (
   select doc.pagopa_ric_doc_codice_benef pagopa_codice_benef,
   		  coalesce(doc.pagopa_ric_doc_soggetto_id,-1) pagopa_soggetto_id, -- 04.06.2019 siac-6720
		  doc.pagopa_ric_doc_str_amm pagopa_str_amm ,
          doc.pagopa_ric_doc_voce_tematica pagopa_voce_tematica,
		  doc.pagopa_ric_doc_voce_code pagopa_voce_code,  doc.pagopa_ric_doc_voce_desc pagopa_voce_desc,
          doc.pagopa_ric_doc_anno_accertamento pagopa_anno_accertamento,
          doc.pagopa_ric_doc_num_accertamento  pagopa_num_accertamento,
          doc.pagopa_ric_doc_tipo_code pagopa_doc_tipo_code, -- siac-6720
          doc.pagopa_ric_doc_tipo_id pagopa_doc_tipo_id,           -- siac-6720
          doc.pagopa_ric_doc_iuv     pagopa_doc_iuv ,   -- 06.02.2020 Sofia siac-7375
          doc.pagopa_ric_doc_data_operazione pagopa_doc_data_operazione -- 06.02.2020 Sofia siac-7375
   from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
   where flusso.pagopa_elab_id=filePagoPaElabId
   and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
   and   doc.pagopa_ric_doc_stato_elab='N'
   and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
   and   doc.pagopa_ric_doc_subdoc_id is null
   --     26.07.2019 Sofia questo controllo causa
   --     la non elaborazione di flussi che hanno dettagli in scarto
   --     righe dello stesso flusso ma con motivi diversi
   --     possono esserci righe con scarto='X' e scarto='N'
   --     per le update a step successivi che hanno la stessa condizione
   --     in questo modo il flusso non viene elaborato
   --     non tutti i dettagli in scarto vengono trattati ed eventualmente associati
   --     a un motivo di scarto
   --     bisogna tenerne conto quando un  flusso non viene elaborato
   --     e non tutti i dettagli hanno un motivo di scarto segnalato
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
            coalesce(doc.pagopa_ric_doc_soggetto_id,-1), -- 04.06.2019 siac-6720
			doc.pagopa_ric_doc_str_amm,
            doc.pagopa_ric_doc_voce_tematica,
            doc.pagopa_ric_doc_voce_code,
            doc.pagopa_ric_doc_voce_desc,
            doc.pagopa_ric_doc_anno_accertamento,
            doc.pagopa_ric_doc_num_accertamento,
            doc.pagopa_ric_doc_tipo_code, -- siac-6720
            doc.pagopa_ric_doc_tipo_id, -- siac-6720
            doc.pagopa_ric_doc_iuv ,   -- 06.02.2020 Sofia siac-7375
            doc.pagopa_ric_doc_data_operazione -- 06.02.2020 Sofia siac-7375
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
---        left join sogg on (pagopa.pagopa_codice_benef=sogg.soggetto_code) -- 04.06.2019 siac-6720
        left join sogg on (pagopa.pagopa_soggetto_id=sogg.soggetto_id)
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
   from   accertamenti --, soggetto_acc -- 22.07.2019 siac-6963
          left join soggetto_acc on (accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id) -- 22.07.2019 siac-6963
--   where  accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id -- 22.07.2019 siac-6963
   )
   select  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end )  pagopa_soggetto_code,
   		   ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ) pagopa_soggetto_desc,
		   ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ) pagopa_soggetto_id,
           pagopa_sogg.pagopa_str_amm,
           pagopa_sogg.pagopa_voce_tematica,
           pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
           pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id, -- siac-6720
           pagopa_sogg.pagopa_doc_iuv, pagopa_sogg.pagopa_doc_data_operazione -- 06.02.2020 Sofia siac-7375
   from  pagopa_sogg, accertamenti_sogg
   where pagopa_sogg.pagopa_anno_accertamento=accertamenti_sogg.movgest_anno
   and   pagopa_sogg.pagopa_num_accertamento=accertamenti_sogg.movgest_numero
   group by ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
            ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ),
            ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end )  ,
            pagopa_sogg.pagopa_str_amm,
            pagopa_sogg.pagopa_voce_tematica,
            pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
            pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id,  -- siac-6720
            pagopa_sogg.pagopa_doc_iuv, pagopa_sogg.pagopa_doc_data_operazione -- 06.02.2020 Sofia siac-7375
   order by  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
   			 pagopa_sogg.pagopa_str_amm,
             pagopa_sogg.pagopa_voce_tematica,
			 pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
             pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id  -- siac-6720

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
		docIUV:=null;
        -- 06.02.2020 Sofia jira siac-7375
        docDataOperazione:=null;

		-- 12.08.2019 Sofia SIAC-6978 - inizio
		if pagoPaFlussoRec.pagopa_doc_tipo_code=DOC_TIPO_FAT then
          strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                        ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                        ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')||' [siac_t_doc].'
                        ||' Lettura codice IUV.';
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

         /* select distinct query.pagopa_ric_doc_iuv into docIUV
          from
          (
             with
             pagopa_sogg as
             (
             with
             pagopa as
             (
             select doc.pagopa_ric_doc_codice_benef pagopa_codice_benef,
                    coalesce(doc.pagopa_ric_doc_soggetto_id,-1) pagopa_soggetto_id, -- 04.06.2019 siac-6720
                    doc.pagopa_ric_doc_str_amm pagopa_str_amm ,
                    doc.pagopa_ric_doc_voce_tematica pagopa_voce_tematica,
                    doc.pagopa_ric_doc_voce_code pagopa_voce_code,  doc.pagopa_ric_doc_voce_desc pagopa_voce_desc,
                    doc.pagopa_ric_doc_anno_accertamento pagopa_anno_accertamento,
                    doc.pagopa_ric_doc_num_accertamento  pagopa_num_accertamento,
                    doc.pagopa_ric_doc_tipo_code pagopa_doc_tipo_code, -- siac-6720
                    doc.pagopa_ric_doc_tipo_id pagopa_doc_tipo_id, -- siac-6720
                    doc.pagopa_ric_doc_iuv pagopa_ric_doc_iuv
             from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
             where flusso.pagopa_elab_id=filePagoPaElabId
             and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
             and   doc.pagopa_ric_doc_stato_elab='N'
             and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
             and   doc.pagopa_ric_doc_subdoc_id is null
             --     26.07.2019 Sofia questo controllo causa
             --     la non elaborazione di flussi che hanno dettagli in scarto
             --     righe dello stesso flusso ma con motivi diversi
             --     possono esserci righe con scarto='X' e scarto='N'
             --     per le update a step successivi che hanno la stessa condizione
             --     in questo modo il flusso non viene elaborato
             --     non tutti i dettagli in scarto vengono trattati ed eventualmente associati
             --     a un motivo di scarto
             --     bisogna tenerne conto quando un  flusso non viene elaborato
             --     e non tutti i dettagli hanno un motivo di scarto segnalato
             -- 06.12.2019 Sofia jira SIAC-7251  -- errore in esecuzione e poi scarto
            /* and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
             (
               select 1
               from pagopa_t_riconciliazione_doc doc1
               where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
               and   doc1.pagopa_ric_doc_stato_elab!='N'
               and   doc1.data_cancellazione is null
               and   doc1.validita_fine is null
             )*/
             and   doc.data_cancellazione is null
             and   doc.validita_fine is null
             and   flusso.data_cancellazione is null
             and   flusso.validita_fine is null
             group by doc.pagopa_ric_doc_codice_benef,
                      coalesce(doc.pagopa_ric_doc_soggetto_id,-1), -- 04.06.2019 siac-6720
                      doc.pagopa_ric_doc_str_amm,
                      doc.pagopa_ric_doc_voce_tematica,
                      doc.pagopa_ric_doc_voce_code,
                      doc.pagopa_ric_doc_voce_desc,
                      doc.pagopa_ric_doc_anno_accertamento,
                      doc.pagopa_ric_doc_num_accertamento,
                      doc.pagopa_ric_doc_tipo_code, -- siac-6720
                      doc.pagopa_ric_doc_tipo_id, -- siac-6720
                      doc.pagopa_ric_doc_iuv
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
          ---        left join sogg on (pagopa.pagopa_codice_benef=sogg.soggetto_code) -- 04.06.2019 siac-6720
                  left join sogg on (pagopa.pagopa_soggetto_id=sogg.soggetto_id)
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
             from   accertamenti --, soggetto_acc -- 22.07.2019 siac-6963
                    left join soggetto_acc on (accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id) -- 22.07.2019 siac-6963
          --   where  accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id -- 22.07.2019 siac-6963
             )
             select  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end )  pagopa_soggetto_code,
                     ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ) pagopa_soggetto_desc,
                     ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ) pagopa_soggetto_id,
                     pagopa_sogg.pagopa_str_amm,
                     pagopa_sogg.pagopa_voce_tematica,
                     pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
                     pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id, -- siac-6720,
                     pagopa_sogg.pagopa_ric_doc_iuv
             from  pagopa_sogg, accertamenti_sogg
             where pagopa_sogg.pagopa_anno_accertamento=accertamenti_sogg.movgest_anno
             and   pagopa_sogg.pagopa_num_accertamento=accertamenti_sogg.movgest_numero
             group by ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
                      ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ),
                      ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end )  ,
                      pagopa_sogg.pagopa_str_amm,
                      pagopa_sogg.pagopa_voce_tematica,
                      pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
                      pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id,  -- siac-6720
                      pagopa_sogg.pagopa_ric_doc_iuv
             order by  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
                       pagopa_sogg.pagopa_str_amm,
                       pagopa_sogg.pagopa_voce_tematica,
                       pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
                       pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id
          )
          query
          where query.pagopa_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id
          and   coalesce(query.pagopa_voce_tematica,'')=coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(query.pagopa_voce_tematica,''))
          and   query.pagopa_voce_code=pagoPaFlussoRec.pagopa_voce_code
          and   coalesce(query.pagopa_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(query.pagopa_voce_desc,''))
          and   coalesce(query.pagopa_str_amm,'')=coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(query.pagopa_str_amm,''))
          and   query.pagopa_soggetto_id=pagoPaFlussoRec.pagopa_soggetto_id;*/

        -- 06.02.2020 Sofia jira siac-7375
        docIUV:=pagoPaFlussoRec.pagopa_doc_iuv;
        raise notice 'IUUUUUUUUUV docIUV=%',docIUV;
       	if coalesce(docIUV,'')='' or docIUV is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Lettura non riuscita.';
        end if;
        -- 06.02.2020 Sofia jira siac-7375
        docDataOperazione:=pagoPaFlussoRec.pagopa_doc_data_operazione;
        raise notice 'IUUUUUUUUUV docDataOperazione=%',docDataOperazione;

       end if;
 	   -- 12.08.2019 Sofia SIAC-6978 - fine


       if bErrore=false then
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

        -- 12.06.2019 SIAC-6720
--        nProgressivo:=nProgressivo+1;
        nProgressivoTemp:=null;
        isDocIPA:=false;
        -- 13.09.2019 Sofia SIAC-7034
        numeroFattura:=null;

        if pagoPaFlussoRec.pagopa_doc_tipo_code=DOC_TIPO_FAT and docTipoFatNumAutom is not null then
        	nProgressivoFat:=nProgressivoFat+1;
            nProgressivoTemp:=nProgressivoFat;
            -- 13.09.2019 Sofia SIAC-7034
            numeroFattura:= pagoPaFlussoRec.pagopa_voce_code||'-'||nProgressivoTemp::varchar;
        end if;
        if pagoPaFlussoRec.pagopa_doc_tipo_code=DOC_TIPO_COR and docTipoCorNumAutom is not null then
        	nProgressivoCor:=nProgressivoCor+1;
            nProgressivoTemp:=nProgressivoCor;
        end if;
        if nProgressivoTemp is null then
	          nProgressivo:=nProgressivo+1;
              nProgressivoTemp:=nProgressivo;
              isDocIPA:=true;
        end if;

        -- 13.09.2019 Sofia SIAC-7034
        if numeroFattura is null then
           numeroFattura:= pagoPaFlussoRec.pagopa_voce_code||' '
                          ||extract ( day from dataElaborazione)||'-'
                          ||lpad(extract ( month from dataElaborazione)::varchar,2,'0')
                          ||'-'||extract ( year from dataElaborazione)
                          -- ||' ' 20.04.2020 Sofia jira	SIAC-7586
                          ||' '||nProgressivoTemp::varchar;
        end if;



--        raise notice 'pagoPaFlussoRec.pagopa_doc_tipo_code=%',pagoPaFlussoRec.pagopa_doc_tipo_code;
--        raise notice 'isDocIPA=%',isDocIPA;
--		raise notice 'nProgressivo=%',nProgressivo;
--        raise notice 'nProgressivoCor=%',nProgressivoCor;
--        raise notice 'nProgressivoFat=%',nProgressivoFat;
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
	        pccuff_id,
            IUV, -- null ??  -- 12.08.2019 Sofia SIAC-6978 - fine
            doc_data_operazione -- 06.02.2020 Sofia jira siac-7375
        )
        select annoBilancio,
--               pagoPaFlussoRec.pagopa_voce_code||' '||dataElaborazione||' '||nProgressivoTemp::varchar,
               numeroFattura,-- 13.09.2019 Sofia SIAC-7034
               upper('Incassi '
               		 ||substring(coalesce(pagoPaFlussoRec.pagopa_voce_tematica,' '),1,30)||' '
                     ||pagoPaFlussoRec.pagopa_voce_code||' '
                     ||substring(coalesce(pagoPaFlussoRec.pagopa_voce_desc,' '),1,30) ||' '||strElencoFlussi),
			   dDocImporto,
               dataElaborazione,
               dataElaborazione,
--			   docTipoId, siac-6720 28.05.2019 Sofia
               pagoPaFlussoRec.pagopa_doc_tipo_id, -- siac-6720 28.05.2019 Sofia
               codBolloId,
               clock_timestamp(),
               enteProprietarioId,
               loginOperazione,
               loginOperazione,
               loginOperazione,
               null,
               null,
               docIUV,   -- 12.08.2019 Sofia SIAC-6978 - fine
               docDataOperazione -- 06.02.2020 Sofia jira siac-7375
        returning doc_id into docId;
--	    raise notice 'docid=%',docId;
		if docId is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
        end if;
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
                --clock_timestamp(), 06.07.2021 Sofia Jira SIAC-8277
                now(), -- 06.07.2021 Sofia Jira SIAC-8277
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
         --- 12.06.2019 Siac-6720
--         raise notice 'pagoPaFlussoRec.pagopa_doc_tipo_code2=%',pagoPaFlussoRec.pagopa_doc_tipo_code;
         if isDocIPA=true then
           update siac_t_doc_num num
           set    doc_numero=num.doc_numero+1,
                  data_modifica=clock_timestamp()
           where  num.ente_proprietario_id=enteProprietarioid
           and    num.doc_anno=annoBilancio
           and    num.doc_tipo_id=docTipoId
           returning num.doc_num_id into codResult;
         else
           update siac_t_doc_num num
           set    doc_numero=num.doc_numero+1,
                  data_modifica=clock_timestamp()
           where  num.ente_proprietario_id=enteProprietarioid
           and    num.doc_anno=annoBilancio
           and    num.doc_tipo_id =pagoPaFlussoRec.pagopa_doc_tipo_id
           returning num.doc_num_id into codResult;
         end if;
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
--        raise notice 'strMessaggio=%',strMessaggio;
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
raise notice 'prima di quote berrore=%',berrore;
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
           and   doc.pagopa_ric_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id -- 30.05.2019 siac-6720
           and   coalesce(doc.pagopa_ric_doc_iuv,'')=coalesce(pagoPaFlussoRec.pagopa_doc_iuv,'') -- 06.02.2020 Sofia siac-7375
           and   coalesce(doc.pagopa_ric_doc_data_operazione,'2020-01-01'::timestamp)=
                 coalesce(pagoPaFlussoRec.pagopa_doc_data_operazione,'2020-01-01'::timestamp) -- 06.02.2020 Sofia siac-7375
           and   coalesce(doc.pagopa_ric_doc_voce_tematica,'')=coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
           and   doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
           and   coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
           and   coalesce(doc.pagopa_ric_doc_str_amm,'')=coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
		   and   doc.pagopa_ric_doc_stato_elab='N'
           and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
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
		   from   accertamenti -- , soggetto_acc -- 22.07.2019 siac-6963
                  left join soggetto_acc on (accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id) -- 22.07.2019 siac-6963
--		   where  accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id -- 22.07.2019 siac-6963
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
--        raise notice 'strMessagio=%',strMessaggio;
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
	        subdoc_importo_da_dedurre, -- 05.06.2019 SIAC-6893
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
            'M', --- 13.12.2018 Sofia siac-6602
            0,   --- 05.06.2019 SIAC-6893
  			docId,
            subDocTipoId,
            clock_timestamp(),
            enteProprietarioId,
            loginOperazione,
            loginOperazione,
            loginOperazione
        )
        returning subdoc_id into subDocId;
--        raise notice 'subdocId=%',subdocId;
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
--		    raise notice 'dispAccertamento=%',dispAccertamento;
            if dispAccertamento is not null then
            	if dispAccertamento-pagoPaFlussoQuoteRec.pagopa_sottovoce_importo<0 then
                     -- 11.06.2019 SIAC-6720 - inserimento movimento di modifica acc automatico
		      		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar
                         ||'. Adeguamento importo Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
      					 ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||'. Inserimento mov. modifica. Calcolo numero.';


                    numModifica:=null;
                    codResult:=null;
                    select coalesce(max(query.mod_num),0) into numModifica
                    from
                    (
					select  modif.mod_num
					from siac_t_modifica modif, siac_r_modifica_stato rs,siac_t_movgest_ts_det_mod  mod
                    where mod.movgest_ts_id=movgestTsId
                    and   rs.mod_stato_r_id=mod.mod_stato_r_id
                    and   modif.mod_id=rs.mod_id
                    and   mod.data_cancellazione is null
                    and   mod.validita_fine is null
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
                    and   modif.data_cancellazione is null
                    and   modif.validita_fine is null
                    union
					select modif.mod_num
					from siac_t_modifica modif, siac_r_modifica_stato rs,siac_r_movgest_ts_sog_mod  mod
                    where mod.movgest_ts_id=movgestTsId
                    and   rs.mod_stato_r_id=mod.mod_stato_r_id
                    and   modif.mod_id=rs.mod_id
                    and   mod.data_cancellazione is null
                    and   mod.validita_fine is null
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
                    and   modif.data_cancellazione is null
                    and   modif.validita_fine is null
                    union
					select modif.mod_num
					from siac_t_modifica modif, siac_r_modifica_stato rs,siac_r_movgest_ts_sogclasse_mod  mod
                    where mod.movgest_ts_id=movgestTsId
                    and   rs.mod_stato_r_id=mod.mod_stato_r_id
                    and   modif.mod_id=rs.mod_id
                    and   mod.data_cancellazione is null
                    and   mod.validita_fine is null
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
                    and   modif.data_cancellazione is null
                    and   modif.validita_fine is null
                    ) query;

                    if numModifica is null then
                     numModifica:=0;
                    end if;

                    strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar
                         ||'. Adeguamento importo Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
      					 ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||'. Inserimento mov. modifica.';
                    attoAmmId:=null;
                    select ratto.attoamm_id into attoAmmId
                    from siac_r_movgest_ts_atto_amm ratto
                    where ratto.movgest_ts_id=movgestTsId
                    and   ratto.data_cancellazione is null
                    and   ratto.validita_fine is null;
					if attoAmmId is null then
                    	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in lettura atto amministrativo.';
                    end if;

                    if codResult is null and modificaTipoId is null then
                    	select tipo.mod_tipo_id into modificaTipoId
                        from siac_d_modifica_tipo tipo
                        where tipo.ente_proprietario_id=enteProprietarioId
                        and   tipo.mod_tipo_code='ALT';
                        if modificaTipoId is null then
                        	codResult:=-1;
	                        strMessaggio:=strMessaggio||' Errore in lettura modifica tipo.';
                        end if;
                    end if;

                    if codResult is null then
                      modifId:=null;
                      insert into siac_t_modifica
                      (
                          mod_num,
                          mod_desc,
                          mod_data,
                          mod_tipo_id,
                          attoamm_id,
                          login_operazione,
                          validita_inizio,
                          ente_proprietario_id
                      )
                      values
                      (
                          numModifica+1,
                          'Modifica automatica per predisposizione di incasso',
                          dataElaborazione,
                          modificaTipoId,
                          attoAmmId,
                          loginOperazione||'@ELAB_PAGOPA-'||filePagoPaElabId::varchar, -- 27.02.2020 Sofia jira SIAC-7449
                          clock_timestamp(),
                          enteProprietarioId
                      )
                      returning mod_id into modifId;
                      if modifId is null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in inserimento siac_t_modifica.';
                      end if;
					end if;

                    if codResult is null and modifStatoId is null then
	                    select stato.mod_stato_id into modifStatoId
                        from siac_d_modifica_stato stato
                        where stato.ente_proprietario_id=enteProprietarioId
                        and   stato.mod_stato_code='V';
                        if modifStatoId is null then
                        	codResult:=-1;
	                        strMessaggio:=strMessaggio||' Errore in lettura stato modifica.';
                        end if;
                    end if;
                    if codResult is null then
                      modStatoRId:=null;
                      insert into siac_r_modifica_stato
                      (
                          mod_id,
                          mod_stato_id,
                          validita_inizio,
                          login_operazione,
                          ente_proprietario_id
                      )
                      values
                      (
                          modifId,
                          modifStatoId,
                          clock_timestamp(),
                          loginOperazione||'@ELAB_PAGOPA'||filePagoPaElabId::varchar, -- 27.02.2020 Sofia jira SIAC-7449
                          enteProprietarioId
                      )
                      returning mod_stato_r_id into modStatoRId;
                      if modStatoRId is  null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in inserimento siac_r_modifica_stato.';
                      end if;
                    end if;
                    if codResult is null then
                      insert into siac_t_movgest_ts_det_mod
                      (
                          mod_stato_r_id,
                          movgest_ts_det_id,
                          movgest_ts_id,
                          movgest_ts_det_tipo_id,
                          movgest_ts_det_importo,
                          validita_inizio,
                          login_operazione,
                          ente_proprietario_id
                      )
                      select modStatoRId,
                             det.movgest_ts_det_id,
                             det.movgest_ts_id,
                             det.movgest_ts_det_tipo_id,
                             pagoPaFlussoQuoteRec.pagopa_sottovoce_importo-dispAccertamento,
                             clock_timestamp(),
                             loginOperazione||'@ELAB_PAGOPA'||filePagoPaElabId::varchar, -- 27.02.2020 Sofia jira SIAC-7449
                             det.ente_proprietario_id
                      from siac_t_movgest_ts_det det
                      where det.movgest_ts_id=movgestTsId
                      and   det.movgest_ts_det_tipo_id=movgestTsDetTipoId
                      returning movgest_ts_det_mod_id into codResult;
                      if codResult is null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in inserimento siac_t_movgest_ts_det_mod.';
                      else
                        codResult:=null;
                      end if;
                	end if;

                    if codResult is null then
                      strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                           ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                           ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                           ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar
                           ||'. Adeguamento importo Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
                           ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||'.';
                      update siac_t_movgest_ts_det det
                      set    movgest_ts_det_importo=det.movgest_ts_det_importo+
                                                    (pagoPaFlussoQuoteRec.pagopa_sottovoce_importo-dispAccertamento),
                             data_modifica=clock_timestamp(),
                             --login_operazione=det.login_operazione||'-'||loginOperazione -- 27.02.2020 Sofia jira SIAC-7449
                             login_operazione=loginOperazione||'@ELAB_PAGOPA-'||filePagoPaElabId::varchar -- 27.02.2020 Sofia jira SIAC-7449
                      where det.movgest_ts_id=movgestTsId
                      and   det.movgest_ts_det_tipo_id=movgestTsDetTipoId
                      and   det.data_cancellazione is null
                      and   date_trunc('DAY',now())>=date_trunc('DAY',det.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(det.validita_fine,date_trunc('DAY',now())))
                      returning det.movgest_ts_det_id into codResult;
                      if codResult is null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in aggiornamento siac_t_movgest_ts_det.';
                      else codResult:=null;
                      end if;
                    end if;

                    if codResult is null then
                      strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                           ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                           ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                           ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar
                           ||'. Adeguamento importo Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
                           ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||'. Inserimento pagopa_t_modifica_elab.';
                      insert into pagopa_t_modifica_elab
                      (
                          pagopa_modifica_elab_importo,
                          pagopa_elab_id,
                          subdoc_id,
                          mod_id,
                          movgest_ts_id,
                          validita_inizio,
                          login_operazione,
                          ente_proprietario_id
                      )
                      values
                      (
                          pagoPaFlussoQuoteRec.pagopa_sottovoce_importo-dispAccertamento,
                          filePagoPaElabId,
                          subDocId,
                          modifId,
                          movgestTsId,
                          clock_timestamp(),
                          loginOperazione||'@ELAB_PAGOPA-'||filePagoPaElabId::varchar, -- 27.02.2020 Sofia jira SIAC-7449
                          enteProprietarioId
                      )
                      returning pagopa_modifica_elab_id into codResult;
                      if codResult is null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in inserimento pagopa_t_modifica_elab.';
                      else codResult:=null;
                      end if;
                    end if;

                    if codResult is not null then
                        --bErrore:=true;
                        pagoPaCodeErr:=PAGOPA_ERR_31;
                    	strMessaggioBck:=strMessaggio||' PAGOPA_ERR_31='||PAGOPA_ERR_31||' .';
--                        raise notice '%', strMessaggioBck;
                        strMessaggio:=' ';
                        raise exception '%', strMessaggioBck;
                    end if;
                     -- 11.06.2019 SIAC-6720 - inserimento movimento di modifica acc automatico
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
--        raise notice 'subdocMovgestTsId=%',subdocMovgestTsId;

        -- siac-6720 30.05.2019 - per i corrispettivi non collegare atto_amm
--        if pagoPaFlussoRec.pagopa_doc_tipo_code!=DOC_TIPO_COR  then -- Jira SIAC-7089 14.10.2019 Sofia
        if pagoPaFlussoRec.pagopa_doc_tipo_code=DOC_TIPO_IPA  then    -- Jira SIAC-7089 14.10.2019 Sofia


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
--               clock_timestamp(), 06.07.2021 Sofia Jira SIAC-8277
               now(), --06.07.2021 Sofia Jira SIAC-8277
               loginOperazione||'@PAGOPA-'||filePagoPaElabId::varchar,
               enteProprietarioId
        )
        returning subdoc_provc_id into codResult;
---        raise notice 'subdoc_provc_id=%',codResult;

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
--               login_operazione=docUPD.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
               login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

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
			and    doc.pagopa_ric_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id -- 30.05.2019 siac-6720
            and    coalesce(doc.pagopa_ric_doc_iuv,'')=coalesce(pagoPaFlussoRec.pagopa_doc_iuv,'') -- 06.02.2020 Sofia siac-7375
            and    coalesce(doc.pagopa_ric_doc_data_operazione,'2020-01-01'::timestamp)=
                   coalesce(pagoPaFlussoRec.pagopa_doc_data_operazione,'2020-01-01'::timestamp) -- 06.02.2020 Sofia siac-7375
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
            and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
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
          -- 23.07.2019 siac-6963
          accertamenti_sog as
          (
           with
           accertamenti as
           (
              select ts.movgest_ts_id
              from siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs
              where mov.bil_id=bilancioId
              and   mov.movgest_tipo_id=movgestTipoId
              and   ts.movgest_id=mov.movgest_id
              and   ts.movgest_ts_tipo_id=movgestTsTipoId
              and   rs.movgest_ts_id=ts.movgest_ts_id
              and   rs.movgest_stato_id=movgestStatoId
              and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
              and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
              and   mov.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())))
              and   ts.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
              and   rs.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
           ),
           sog_acc as
           (
              select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc, rsog.movgest_ts_id
              from siac_t_soggetto sog,siac_r_movgest_ts_sog rsog
              where sog.ente_proprietario_id=enteProprietarioId
              and   rsog.soggetto_id=sog.soggetto_id
              and   sog.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
              and   rsog.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',rsog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rsog.validita_fine,date_trunc('DAY',now())))

           )
           select accertamenti.movgest_ts_id, sog_acc.soggetto_id
           from accertamenti left join sog_acc on (accertamenti.movgest_ts_id=sog_acc.movgest_ts_id)
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
                 (case when s1.soggetto_id is not null then s1.soggetto_id else accertamenti_sog.soggetto_id end ) pagopa_soggetto_id
          from --pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code),
--               accertamenti join sog s2 on (accertamenti.soggetto_id=s2.soggetto_id) -- 22.07.2019 siac-6963
               accertamenti_sog ,-- 22.07.2019 siac-6963
               pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code)
        ) QUERY
        where docUPD.ente_proprietario_id=enteProprietarioId
        and   docUPD.pagopa_ric_doc_stato_elab='N'
        and   docUPD.pagopa_ric_doc_subdoc_id is null
        and   docUPD.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
        and   docUPD.pagopa_ric_doc_id=QUERY.pagopa_ric_doc_id
        and   QUERY.pagopa_soggetto_id=pagoPaFlussoQuoteRec.pagopa_soggetto_id
        and   docUPD.data_cancellazione is null
        and   docUPD.validita_fine is null;
        GET DIAGNOSTICS codResult = ROW_COUNT;
--		raise notice 'Aggiornati pagopa_t_riconciliazione_doc=%',codResult;
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
--               login_operazione=ric.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
               login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

		from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
        where flusso.pagopa_elab_id=filePagoPaElabId
        and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
        and   doc.pagopa_ric_doc_subdoc_id=subdocId
        and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
        and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId
        and   ric.pagopa_ric_id=doc.pagopa_ric_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
--   		raise notice 'Aggiornati pagopa_t_riconciliazione=%',codResult;

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
		raise notice 'dnumQuote %',dnumQuote;
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
--         raise notice 'strMessaggio=%',strMessaggio;
--                  raise notice 'pagoPaCodeErr=%',pagoPaCodeErr;

		 if pagoPaCodeErr is null then
         	pagoPaCodeErr:=PAGOPA_ERR_30;
         end if;

         -- pulizia delle tabella pagopa_t_riconciliazione

         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione S].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
  		 update pagopa_t_riconciliazione ric
         set    pagopa_ric_flusso_stato_elab='X',
  			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                data_modifica=clock_timestamp(),
--                login_operazione=split_part(ric.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
                login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

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
--         raise notice 'strMessaggio=%',strMessaggio;
		 update pagopa_t_riconciliazione  docUPD
         set    pagopa_ric_flusso_stato_elab='X',
  			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                data_modifica=clock_timestamp(),
                --login_operazione=split_part(docUPD.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
                login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar      -- 04.02.2020 Sofia SIAC-7375
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
            and    doc.pagopa_ric_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id -- 30.05.2019 siac-6720
            and   coalesce(doc.pagopa_ric_doc_iuv,'')=coalesce(pagoPaFlussoRec.pagopa_doc_iuv,'') -- 06.02.2020 Sofia siac-7375
            and   coalesce(doc.pagopa_ric_doc_data_operazione,'2020-01-01'::timestamp)=
                  coalesce(pagoPaFlussoRec.pagopa_doc_data_operazione,'2020-01-01'::timestamp) -- 06.02.2020 Sofia siac-7375
            and    coalesce(doc.pagopa_ric_doc_str_amm,'')=
                   coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
            and    coalesce(doc.pagopa_ric_doc_voce_tematica,'')=
                   coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
            and    doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
            and    coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
        --    and    doc.pagopa_ric_doc_sottovoce_code=pagoPaFlussoQuoteRec.pagopa_sottovoce_code
        --    and    coalesce(doc.pagopa_ric_doc_sottovoce_desc,'')=
        --           coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,coalesce(doc.pagopa_ric_doc_sottovoce_desc,''))
        --    and    flusso.pagopa_elab_ric_flusso_id=pagoPaFlussoQuoteRec.pagopa_flusso_id
        --    and    flusso.pagopa_elab_flusso_nome_mittente=pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente
        --    and    flusso.pagopa_elab_flusso_anno_provvisorio=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
        --    and    flusso.pagopa_elab_flusso_num_provvisorio=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
        --   and    doc.pagopa_ric_doc_anno_accertamento=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
        --	 and    doc.pagopa_ric_doc_num_accertamento=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and    doc.pagopa_ric_doc_stato_elab = 'N'
            and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
			and    doc.pagopa_ric_doc_subdoc_id is null
     	/*	and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   		    (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		    )*/
		    and   doc.data_cancellazione is null
		    and   doc.validita_fine is null
	     	and   flusso.data_cancellazione is null
		    and   flusso.validita_fine is null
          ),
          -- 23.07.2019 siac-6963
          accertamenti_sog AS
          (
           with
           accertamenti as
           (
                select ts.movgest_ts_id
                from siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs
                where mov.bil_id=bilancioId
                and   mov.movgest_tipo_id=movgestTipoId
                and   ts.movgest_id=mov.movgest_id
                and   ts.movgest_ts_tipo_id=movgestTsTipoId
                and   rs.movgest_ts_id=ts.movgest_ts_id
                and   rs.movgest_stato_id=movgestStatoId
            --    and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
             --   and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
                and   mov.data_cancellazione is null
                and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())))
                and   ts.data_cancellazione is null
                and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
                and   rs.data_cancellazione is null
                and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
           ),
           sog_acc as
           (
	           select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc, rsog.movgest_ts_id
    		   from siac_t_soggetto sog,siac_r_movgest_ts_sog rsog
	           where sog.ente_proprietario_id=enteProprietarioId
               and   rsog.soggetto_id=sog.soggetto_id
	           and   sog.data_cancellazione is null
	           and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
               and   rsog.data_cancellazione is null
               and   date_trunc('DAY',now())>=date_trunc('DAY',rsog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rsog.validita_fine,date_trunc('DAY',now())))
           )
           select accertamenti.movgest_ts_id, sog_acc.soggetto_id
           from accertamenti left join sog_acc on (accertamenti.movgest_ts_id=sog_acc.movgest_ts_id)
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
                 (case when s1.soggetto_id is not null then s1.soggetto_id else accertamenti_sog.soggetto_id end ) pagopa_soggetto_id,
                 pagopa.pagopa_ric_id
          from pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code),
--                accertamenti join sog s2 on (accertamenti.soggetto_id=s2.soggetto_id) -- 22.07.2019 siac-6963
               accertamenti_sog -- 22.07.2019 siac-6963
         ) query,pagopa_d_riconciliazione_errore errore
         where docUPD.ente_proprietario_id=enteProprietarioId
--         and   docUPD.pagopa_ric_flusso_stato_elab='N'
         and   docUPD.pagopa_ric_id=QUERY.pagopa_ric_id
         and   QUERY.pagopa_soggetto_id=pagoPaFlussoRec.pagopa_soggetto_id
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
--         raise notice 'strMessaggio=%',strMessaggio;

         update pagopa_t_riconciliazione_doc doc
         set    pagopa_ric_doc_stato_elab='X',
			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                pagopa_ric_doc_subdoc_id=null,
                pagopa_ric_doc_movgest_ts_id=null,
                pagopa_ric_doc_provc_id=null,
                data_modifica=clock_timestamp(),
--                login_operazione=split_part(doc.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
                login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar             -- 04.02.2020 Sofia SIAC-7375
         from pagopa_t_elaborazione_flusso flusso,
              pagopa_d_riconciliazione_errore errore, siac_t_subdoc sub
         where flusso.pagopa_elab_id=filePagoPaElabId
         and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
         and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
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
--         raise notice 'strMessaggio=%',strMessaggio;
		 update pagopa_t_riconciliazione_doc  docUPD
         set    pagopa_ric_doc_stato_elab='X',
			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                pagopa_ric_doc_subdoc_id=null,
                pagopa_ric_doc_movgest_ts_id=null,
                pagopa_ric_doc_provc_id=null,
                data_modifica=clock_timestamp(),
--                login_operazione=split_part(docUPD.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
                login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar          -- 04.02.2020 Sofia SIAC-7375
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
            and    doc.pagopa_ric_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id -- 30.05.2019 siac-6720
            and    coalesce(doc.pagopa_ric_doc_iuv,'')=coalesce(pagoPaFlussoRec.pagopa_doc_iuv,'') -- 06.02.2020 Sofia siac-7375
            and    coalesce(doc.pagopa_ric_doc_data_operazione,'2020-01-01'::timestamp)=
                   coalesce(pagoPaFlussoRec.pagopa_doc_data_operazione,'2020-01-01'::timestamp) -- 06.02.2020 Sofia siac-7375
            and    coalesce(doc.pagopa_ric_doc_str_amm,'')=
                   coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
            and    coalesce(doc.pagopa_ric_doc_voce_tematica,'')=
                   coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
            and    doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
            and    coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
--            and    doc.pagopa_ric_doc_sottovoce_code=pagoPaFlussoQuoteRec.pagopa_sottovoce_code
--            and    coalesce(doc.pagopa_ric_doc_sottovoce_desc,'')=
--                   coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,coalesce(doc.pagopa_ric_doc_sottovoce_desc,''))
--            and    flusso.pagopa_elab_ric_flusso_id=pagoPaFlussoQuoteRec.pagopa_flusso_id
--            and    flusso.pagopa_elab_flusso_nome_mittente=pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente
--            and    flusso.pagopa_elab_flusso_anno_provvisorio=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
--            and    flusso.pagopa_elab_flusso_num_provvisorio=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
--            and    doc.pagopa_ric_doc_anno_accertamento=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
--    		and    doc.pagopa_ric_doc_num_accertamento=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and    doc.pagopa_ric_doc_stato_elab = 'N'
			and    doc.pagopa_ric_doc_subdoc_id is null
            and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
  /*   		and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   		    (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		    )*/
		    and   doc.data_cancellazione is null
		    and   doc.validita_fine is null
	     	and   flusso.data_cancellazione is null
		    and   flusso.validita_fine is null
          ),
          -- 23.07.2019 siac-6963
          accertamenti_sog as
          (
           with
           accertamenti as
           (
            select ts.movgest_ts_id
            from siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs
            where mov.bil_id=bilancioID
            and   mov.movgest_tipo_id=movgestTipoId
            and   ts.movgest_id=mov.movgest_id
            and   ts.movgest_ts_tipo_id=movgestTsTipoId
            and   rs.movgest_ts_id=ts.movgest_ts_id
            and   rs.movgest_stato_id=movgestStatoId
--            and   rsog.movgest_ts_id=ts.movgest_ts_id -- 06.12.2019 Sofia jira SIAC-7251  -- errore in esecuzione
  --          and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
  --          and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and   mov.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())))
            and   ts.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
            and   rs.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
           ),
           sog_acc as
           (
            select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc, rsog.movgest_ts_id
            from siac_t_soggetto sog,siac_r_movgest_ts_sog rsog
            where sog.ente_proprietario_id=enteProprietarioId
            and   rsog.soggetto_id=sog.soggetto_id
            and   sog.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
            and   rsog.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',rsog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rsog.validita_fine,date_trunc('DAY',now())))
           )
           select accertamenti.movgest_ts_id, sog_acc.soggetto_id
           from accertamenti left join sog_acc on (accertamenti.movgest_ts_id=sog_acc.movgest_ts_id)
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
                 (case when s1.soggetto_id is not null then s1.soggetto_id else accertamenti_sog.soggetto_id end ) pagopa_soggetto_id,
                 pagopa.pagopa_ric_id
          from pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code),
---               accertamenti join sog s2 on (accertamenti.soggetto_id=s2.soggetto_id) -- 22.07.2019 siac-6963
               accertamenti_sog -- 22.07.2019 siac-6963

         ) query,pagopa_d_riconciliazione_errore errore
         where docUPD.ente_proprietario_id=enteProprietarioId
--         and   docUPD.pagopa_ric_doc_stato_elab='N'
         and   docUPD.pagopa_ric_doc_id=QUERY.pagopa_ric_doc_id
         and   QUERY.pagopa_soggetto_id=pagoPaFlussoRec.pagopa_soggetto_id
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

         -- 11.06.2019 SIAC-6720
         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_modifica_elab].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
		 update pagopa_t_modifica_elab r
         set    pagopa_modifica_elab_note='DOCUMENTO CANCELLATO IN ESEGUI PER pagoPaCodeErr='||pagoPaCodeErr||' ',
                subdoc_id=null
         from 	siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;

         strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_movgest_ts].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;

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
--  raise notice 'strMessaggioLog=%',strMessaggioLog;
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
         data_modifica=clock_timestamp()--, 26.08.2020 Sofia Jira SIAC-7747
         -- login_operazione=num.login_operazione||'-'||loginOperazione 26.08.2020 Sofia Jira SIAC-7747
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
            pagopa_elab_note=
            substr(
             (
              'AGGIORNAMENTO PER ERR.='||(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )::varchar||'.'
              ||elab.pagopa_elab_note
             ),1,1500) -- 09.10.2019 Sofia
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
           file_pagopa_note=
                  substr(
                    ('AGGIORNAMENTO PER ERR.='||(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )::varchar||'.'
                     ||file.file_pagopa_note
                    ),1,1500), -- 09.10.2019 Sofia
           login_operazione=substr(loginOperazione||'-'||file.login_operazione,1,200) -- 09.10.2019 Sofia
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
--  raise notice 'strMessaggio=%',strMessaggio;

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
      and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
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
      and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
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

  --  strMessaggioFinale:='CHIUSURA - '||upper(strMessaggioFinale||' '||strMessaggio); -- 09.10.2019 Sofia
  strMessaggioFinale:='CHIUSURA - '||substr(upper(strMessaggio||' '||strMessaggioFinale),1,1450); -- 09.10.2019 Sofia

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
  --    and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
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
    --  and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
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
   --   and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
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

--       strMessaggioFinale:='CHIUSURA - '||upper(strMessaggioFinale||' '||strMessaggio); -- 09.10.2019 Sofia
       strMessaggioFinale:='CHIUSURA - '||substr(upper(strMessaggio||' '||strMessaggioFinale),1,1450); -- 09.10.2019 Sofia

       update siac_t_file_pagopa file
       set    data_modifica=clock_timestamp(),
              validita_fine=(case when pagoPaCodeErr=ELABORATO_OK_ST then clock_timestamp() else null end),
              file_pagopa_stato_id=stato.file_pagopa_stato_id,
              file_pagopa_note=file.file_pagopa_note||upper(strMessaggioFinale),
--              login_operazione=file.login_operazione||'-'||loginOperazione
              login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

       from  siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
       where file.file_pagopa_id=elabRec.file_pagopa_id
       and   stato.ente_proprietario_id=file.ente_proprietario_id
       and   stato.file_pagopa_stato_code=pagoPaCodeErr;

    end if;

  end loop;

  messaggioRisultato:='OK VERIFICARE STATO ELAB. - '||upper(strMessaggioFinale);
-- raise notice 'messaggioRisultato=%',messaggioRisultato;
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

alter function siac.fnc_pagopa_t_elaborazione_riconc_esegui
( integer, integer, integer , varchar , timestamp ,  
  out integer,
  out varchar) owner to siac;
-- SIAC-8277 Sofia 06072021 fine 

-- SIAC-8276 Sofia 06072021 inizio
drop FUNCTION if exists siac.fnc_pagopa_t_elaborazione_riconc
(
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out outpagopaelabid integer,
  out outpagopaelabprecid integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
);
CREATE OR REPLACE FUNCTION siac.fnc_pagopa_t_elaborazione_riconc(enteproprietarioid integer, loginoperazione character varying, dataelaborazione timestamp without time zone, OUT outpagopaelabid integer, OUT outpagopaelabprecid integer, OUT codicerisultato integer, OUT messaggiorisultato character varying)
 RETURNS record
 AS $body$
DECLARE

	strMessaggio VARCHAR(2500):=''; -- 09.10.2019 Sofia
    strMessaggioBck  VARCHAR(2500):=''; -- 09.10.2019 Sofia
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
	-- 18.01.2021 Sofia jira SIAC-7962
	ESERCIZIO_CONSUNTIVO_ST    CONSTANT  varchar :='O'; -- esercizio consuntivo

	---- 28.10.2020 Sofia SIAC-7672
    elabSvecchiaRec record;
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
     and   fase.fase_operativa_id=r.fase_operativa_id
    -- 18.01.2021 Sofia jira SIAC-7962
--    and   fase.fase_operativa_code in (ESERCIZIO_PROVVISORIO_ST,ESERCIZIO_GESTIONE_ST);
    and   fase.fase_operativa_code in (ESERCIZIO_PROVVISORIO_ST,ESERCIZIO_GESTIONE_ST,ESERCIZIO_CONSUNTIVO_ST);
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
   
   -- SIAC-8276 - inizio 
   strMessaggio:='Verifica esistenza file duplicati.';
   select count(*)  into codResult 
   from siac_t_file_pagopa file,siac_d_file_pagopa_stato stato
   where stato.ente_proprietario_id=enteProprietarioId
   and   stato.file_pagopa_stato_code not in ( 'ANNULLATO','RIFIUTATO')
   and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
   and   file.file_pagopa_anno in (annoBilancio_ini,annoBilancio)
   and file.data_cancellazione is null
   group by file.file_pagopa_id_flusso
   having count(*)>1;

   if codResult is not null then
           outPagoPaElabId:=-1;
           outPagoPaElabPrecId:=-1;
           messaggioRisultato:=upper(strMessaggioFinale||' File duplicati esistenti.');
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
   
   -- SIAC-8276 - fine
   

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

    -- 28.10.2020 Sofia SIAC-7672 - inizio
--	if codiceRisultato=0 and coalesce(filePagoPaElabId,0)!=0 then
--  16.04.2021 Sofia Jira 	SIAC-8163 - attivazione svecchiamento puntuale
    if coalesce(filePagoPaElabId,0)!=0 then
        select * into elabSvecchiaRec
       	from fnc_pagopa_t_elaborazione_riconc_svecchia_err
		(
		  filePagoPaElabId,
	      annoRec.anno_elab,
  		  enteProprietarioId,
		  loginOperazione,
	      dataElaborazione
        );
        if elabSvecchiaRec.codiceRisultato!=0 then
       	  codiceRisultato:=elabSvecchiaRec.codiceRisultato;
          strMessaggio:=elabSvecchiaRec.messaggiorisultato;
        end if;
    end if;
    -- 28.10.2020 Sofia SIAC-7672 - fine

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

alter function
siac.fnc_pagopa_t_elaborazione_riconc
(
 integer,
 varchar,
 timestamp,
 out integer,
 out integer,
 out integer,
 out varchar
) OWNER to siac;
-- SIAC-8276 Sofia 06072021 fine 

--SIAC-8284 - Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR217_equilibri_bilancio_regione_assest_spese" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar
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
  pdc varchar,
  display_error varchar
) AS
$body$
DECLARE

capitoloRec record;
capitoloImportiRec record;
classifBilRec record;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
TipoImpstanzresidui varchar;
elemTipoCode varchar;
user_table	varchar;
tipologia_capitolo	varchar;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
id_bil INTEGER;
strQuery varchar;
strApp varchar;
intApp numeric;
x_array VARCHAR [];

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
TipoImpstanzresidui='STI';	 -- stanziamento residuo
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione

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
pdc='';
 
--14/12/2020 SIAC-7877 introdotta la gestione delle variazioni.
-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  x_array = string_to_array(p_ele_variazioni, ',');
  foreach strApp in ARRAY x_array
  LOOP
    intApp = strApp::INTEGER;
  END LOOP;
END IF;

select t_bil.bil_id
	into id_bil
from siac_t_bil t_bil,
	siac_t_periodo t_periodo
where t_bil.periodo_id=t_periodo.periodo_id
	and t_bil.ente_proprietario_id = p_ente_prop_id
    and t_periodo.anno= p_anno    
    and t_bil.data_cancellazione IS NULL
    and t_periodo.data_cancellazione IS NULL;
IF NOT FOUND THEN
	raise notice 'Codice del bilancio non trovato';
    return;
END IF;

select fnc_siac_random_user()
into	user_table;

display_error:='';

--14/12/2020 SIAC-7877 introdotta la gestione delle variazioni.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
strQuery:= '
    insert into siac_rep_var_spese
    select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),        
        tipo_elemento.elem_det_tipo_code, 
        '''||user_table||''' utente,
        testata_variazione.ente_proprietario_id,
        anno_importi.anno	      	
        from 	siac_r_variazione_stato		r_variazione_stato,
                siac_t_variazione 			testata_variazione,
                siac_d_variazione_tipo		tipologia_variazione,
                siac_d_variazione_stato 	tipologia_stato_var,
                siac_t_bil_elem_det_var 	dettaglio_variazione,
                siac_t_bil_elem				capitolo,
                siac_d_bil_elem_tipo 		tipo_capitolo,
                siac_d_bil_elem_det_tipo	tipo_elemento,
                siac_t_periodo 				anno_eserc ,
                siac_t_bil					t_bil,
                siac_t_periodo 				anno_importi
        where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
        and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
        and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
        and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
        and		dettaglio_variazione.elem_id						=	capitolo.elem_id
        and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
        and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
        and 	t_bil.periodo_id 									=	anno_eserc.periodo_id		
        and 	t_bil.bil_id 										= testata_variazione.bil_id
        and		anno_importi.periodo_id 							=	dettaglio_variazione.periodo_id	
        and 	testata_variazione.ente_proprietario_id 			= 	'||p_ente_prop_id ||'
        and		anno_eserc.anno										= 	'''||p_anno||''' 
        and 	testata_variazione.variazione_num 					in ('||p_ele_variazioni||')  
        and		anno_importi.anno				in 	('''||annoCapImp||''','''||annoCapImp1||''','''||annoCapImp2||''')									
        and		tipologia_stato_var.variazione_stato_tipo_code	in	(''B'',''G'', ''C'', ''P'')
        and		tipo_capitolo.elem_tipo_code						=	'''||elemTipoCode||'''
        and		tipo_elemento.elem_det_tipo_code					in (''STA'',''SCA'',''STR'')
        and		r_variazione_stato.data_cancellazione		is null
        and		testata_variazione.data_cancellazione		is null
        and		tipologia_variazione.data_cancellazione		is null
        and		tipologia_stato_var.data_cancellazione		is null
        and 	dettaglio_variazione.data_cancellazione		is null
        and 	capitolo.data_cancellazione					is null
        and		tipo_capitolo.data_cancellazione			is null
        and		tipo_elemento.data_cancellazione			is null
        and		t_bil.data_cancellazione					is null
        group by 	dettaglio_variazione.elem_id,
                    tipo_elemento.elem_det_tipo_code, 
                    utente,
                    testata_variazione.ente_proprietario_id,
                    anno_importi.anno';                    

	raise notice 'Query variazioni spesa = %', strQuery;
    execute  strQuery;
end if;
    
return query
	with strut_bilancio as(
     		select  *
            from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id, p_anno,'')),
    capitoli as(
    	select 	programma.classif_id programma_id,
			macroaggr.classif_id macroaggregato_id,
        	p_anno anno_bilancio,
       		capitolo.*,cat_del_capitolo.elem_cat_code
		from 
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
		where capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 	and
            programma.classif_tipo_id	=programma_tipo.classif_tipo_id and
            programma.classif_id	=r_capitolo_programma.classif_id and
            macroaggr.classif_tipo_id	=macroaggr_tipo.classif_tipo_id and
    		macroaggr.classif_id	=r_capitolo_macroaggr.classif_id and			     		 
    		capitolo.elem_id=r_capitolo_programma.elem_id	and
    		capitolo.elem_id=r_capitolo_macroaggr.elem_id	and
    		capitolo.elem_id		=	r_capitolo_stato.elem_id and
			r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id and
			capitolo.elem_id				=	r_cat_capitolo.elem_id	and
			r_cat_capitolo.elem_cat_id	=cat_del_capitolo.elem_cat_id and
            capitolo.bil_id 				= id_bil and
            capitolo.ente_proprietario_id	=	p_ente_prop_id	and
    		tipo_elemento.elem_tipo_code = elemTipoCode		and	
			programma_tipo.classif_tipo_code	='PROGRAMMA'  and		        
    		macroaggr_tipo.classif_tipo_code	='MACROAGGREGATO' and   
			stato_capitolo.elem_stato_code	=	'VA'	and
    		cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC') and 
			programma_tipo.data_cancellazione			is null 	and
    		programma.data_cancellazione 				is null 	and
    		macroaggr_tipo.data_cancellazione	 		is null 	and
    		macroaggr.data_cancellazione 				is null 	and
    		tipo_elemento.data_cancellazione 			is null 	and
    		r_capitolo_programma.data_cancellazione 	is null 	and
    		r_capitolo_macroaggr.data_cancellazione 	is null 	and    		
    		stato_capitolo.data_cancellazione 			is null 	and 
    		r_capitolo_stato.data_cancellazione 		is null 	and
			cat_del_capitolo.data_cancellazione 		is null 	and
    		r_cat_capitolo.data_cancellazione 			is null 	and
			capitolo.data_cancellazione 				is null),
pdc_capitolo as (
select r_capitolo_pdc.elem_id,
	 pdc.classif_code pdc_code
from siac_r_bil_elem_class r_capitolo_pdc,
     siac_t_class pdc,
     siac_d_class_tipo pdc_tipo
where r_capitolo_pdc.classif_id = pdc.classif_id and
  	 pdc.classif_tipo_id 		= pdc_tipo.classif_tipo_id and
     r_capitolo_pdc.ente_proprietario_id	=	p_ente_prop_id and 
     pdc_tipo.classif_tipo_code like 'PDC_%'		and
     r_capitolo_pdc.data_cancellazione 			is null and 	
     pdc.data_cancellazione is null 	and
     pdc_tipo.data_cancellazione 	is null),           
imp_comp_anno as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
        and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_comp_anno1 as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp1 
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
        and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_comp_anno2 as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp2 
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
        and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_cassa_anno as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 	
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpCassa --'SCA'
        and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_residui_anno as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpRes --'STR'
        and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_comp_fpv_anno as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
        and	cat_del_capitolo.elem_cat_code	in ('FPV','FPVC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_comp_fpv_anno1 as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp1
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
        and	cat_del_capitolo.elem_cat_code	in ('FPV','FPVC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_comp_fpv_anno2 as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp2
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp --'STA
        and	cat_del_capitolo.elem_cat_code	in ('FPV','FPVC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_res_anno_prec as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpstanzresidui --'STI'
        and	cat_del_capitolo.elem_cat_code	in ('STD','FSC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
imp_res_fpv_anno_prec as (
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            capitolo_importi.ente_proprietario_id,   
            sum(capitolo_importi.elem_det_importo) importo  
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						        
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo.bil_id 					= id_bil
        and capitolo_importi.ente_proprietario_id = p_ente_prop_id 
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
		and	stato_capitolo.elem_stato_code		=	'VA'
        and	capitolo_imp_periodo.anno = annoCapImp
        and	capitolo_imp_tipo.elem_det_tipo_code = TipoImpstanzresidui --'STI'
        and	cat_del_capitolo.elem_cat_code	in ('FPV','FPVC')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
        group by capitolo_importi.elem_id,
    	capitolo_imp_periodo.anno, capitolo_importi.ente_proprietario_id),
variaz_stanz_anno as (
	select a.elem_id, sum(a.importo) importo_stanz
    from siac_rep_var_spese a
    where a.ente_proprietario= p_ente_prop_id
    	and a.utente=user_table
        and a.tipologia = TipoImpComp --STA Competenza
        and a.periodo_anno = annoCapImp
    group by a.elem_id),
variaz_stanz_anno1 as (
	select a.elem_id, sum(a.importo) importo_stanz1
    from siac_rep_var_spese a
    where a.ente_proprietario= p_ente_prop_id
    	and a.utente=user_table
        and a.tipologia = TipoImpComp --STA Competenza
        and a.periodo_anno = annoCapImp1
    group by a.elem_id),
variaz_stanz_anno2 as (
	select a.elem_id, sum(a.importo) importo_stanz2
    from siac_rep_var_spese a
    where a.ente_proprietario= p_ente_prop_id
    	and a.utente=user_table
        and a.tipologia = TipoImpComp --STA Competenza
        and a.periodo_anno = annoCapImp2
    group by a.elem_id),        
variaz_cassa_anno as (
	select a.elem_id, sum(a.importo) importo_cassa
    from siac_rep_var_spese a
    where a.ente_proprietario= p_ente_prop_id
    	and a.utente=user_table
        and a.tipologia = TipoImpCassa --SCA Cassa
        and a.periodo_anno = annoCapImp
    group by a.elem_id),  
variaz_residui_anno as (
	select a.elem_id, sum(a.importo) importo_residui
    from siac_rep_var_spese a
    where a.ente_proprietario= p_ente_prop_id
    	and a.utente=user_table
        and a.tipologia = TipoImpRes --STR Residui
        and a.periodo_anno = annoCapImp
    group by a.elem_id)                                                                                                       
select 
   capitoli.anno_bilancio::varchar bil_anno,
   ''::varchar missione_tipo_code,
   strut_bilancio.missione_tipo_desc::varchar missione_tipo_desc,
   strut_bilancio.missione_code::varchar missione_code,
   strut_bilancio.missione_desc::varchar missione_desc,
   ''::varchar programma_tipo_code,
   strut_bilancio.programma_tipo_desc::varchar programma_tipo_desc,
   strut_bilancio.programma_code::varchar programma_code,
   strut_bilancio.programma_desc::varchar programma_desc,
   ''::varchar titusc_tipo_code,
   strut_bilancio.titusc_tipo_desc::varchar titusc_tipo_desc,
   strut_bilancio.titusc_code::varchar titusc_code,
   strut_bilancio.titusc_desc::varchar titusc_desc,
   ''::varchar macroag_tipo_code,
   strut_bilancio.macroag_tipo_desc::varchar macroag_tipo_desc,
   strut_bilancio.macroag_code::varchar macroag_code,
   strut_bilancio.macroag_desc::varchar macroag_desc,
   capitoli.elem_code::varchar bil_ele_code,
   capitoli.elem_desc::varchar bil_ele_desc,
   capitoli.elem_code2::varchar bil_ele_code2,
   capitoli.elem_desc2::varchar bil_ele_desc2,
   capitoli.elem_id::integer bil_ele_id,
   capitoli.elem_id_padre::integer bil_ele_id_padre,
-- 14/12/2020 SIAC-7877 introdotta la gestione delle variazioni.   
   (COALESCE(imp_residui_anno.importo,0) +
    COALESCE(variaz_residui_anno.importo_residui,0))::numeric stanziamento_prev_res_anno,   
   COALESCE(imp_res_anno_prec.importo,0)::numeric stanziamento_anno_prec,
   (COALESCE(imp_cassa_anno.importo,0) +
    COALESCE(variaz_cassa_anno.importo_cassa,0))::numeric stanziamento_prev_cassa_anno,
   (COALESCE(imp_comp_anno.importo,0) +
    COALESCE(variaz_stanz_anno.importo_stanz,0))::numeric stanziamento_prev_anno,
   (COALESCE(imp_comp_anno1.importo,0) +
    COALESCE(variaz_stanz_anno1.importo_stanz1,0))::numeric stanziamento_prev_anno1,
   (COALESCE(imp_comp_anno2.importo,0) +
    COALESCE(variaz_stanz_anno2.importo_stanz2,0))::numeric stanziamento_prev_anno2,
   0::numeric impegnato_anno,
   0::numeric impegnato_anno1,
   0::numeric impegnato_anno2,
   COALESCE(imp_res_fpv_anno_prec.importo,0)::numeric stanziamento_fpv_anno_prec,
   	--08/07/2021 SIAC-8284
    -- devo sommare l'importo variazione all'importo FPV solo se il capitolo e'
    -- di tipo FPV.
   case when COALESCE(capitoli.elem_cat_code,'') in('FPV','FPVC') then
   	(COALESCE(imp_comp_fpv_anno.importo,0) +
    	COALESCE(variaz_stanz_anno.importo_stanz,0))::numeric
   else COALESCE(imp_comp_fpv_anno.importo,0)::numeric end  stanziamento_fpv_anno,
   --08/07/2021 SIAC-8284
    -- devo sommare l'importo variazione all'importo FPV solo se il capitolo e'
    -- di tipo FPV.
   case when COALESCE(capitoli.elem_cat_code,'') in('FPV','FPVC') then
   	(COALESCE(imp_comp_fpv_anno1.importo,0) +
    	COALESCE(variaz_stanz_anno1.importo_stanz1,0))::numeric 
   else COALESCE(imp_comp_fpv_anno1.importo,0)::numeric end stanziamento_fpv_anno1,
   --08/07/2021 SIAC-8284
    -- devo sommare l'importo variazione all'importo FPV solo se il capitolo e'
    -- di tipo FPV.
   case when COALESCE(capitoli.elem_cat_code,'') in('FPV','FPVC') then
   	(COALESCE(imp_comp_fpv_anno2.importo,0) +
    	COALESCE(variaz_stanz_anno2.importo_stanz2,0))::numeric 
   else COALESCE(imp_comp_fpv_anno2.importo,0)::numeric end stanziamento_fpv_anno2,
   pdc_capitolo.pdc_code::varchar pdc,
   display_error::varchar display_error    
from strut_bilancio
	LEFT JOIN capitoli on (strut_bilancio.programma_id = capitoli.programma_id
    						AND strut_bilancio.macroag_id = capitoli.macroaggregato_id)
    LEFT JOIN pdc_capitolo on capitoli.elem_id = pdc_capitolo.elem_id    
    LEFT JOIN imp_comp_anno on capitoli.elem_id = imp_comp_anno.elem_id
    LEFT JOIN imp_comp_anno1 on capitoli.elem_id = imp_comp_anno1.elem_id
    LEFT JOIN imp_comp_anno2 on capitoli.elem_id = imp_comp_anno2.elem_id
    LEFT JOIN imp_cassa_anno on capitoli.elem_id = imp_cassa_anno.elem_id
    LEFT JOIN imp_residui_anno on capitoli.elem_id = imp_residui_anno.elem_id
    LEFT JOIN imp_comp_fpv_anno on capitoli.elem_id = imp_comp_fpv_anno.elem_id
    LEFT JOIN imp_comp_fpv_anno1 on capitoli.elem_id = imp_comp_fpv_anno1.elem_id
    LEFT JOIN imp_comp_fpv_anno2 on capitoli.elem_id = imp_comp_fpv_anno2.elem_id
    LEFT JOIN imp_res_anno_prec on capitoli.elem_id = imp_res_anno_prec.elem_id
    LEFT JOIN imp_res_fpv_anno_prec on capitoli.elem_id = imp_res_fpv_anno_prec.elem_id
    LEFT JOIN variaz_stanz_anno on capitoli.elem_id = variaz_stanz_anno.elem_id
    LEFT JOIN variaz_stanz_anno1 on capitoli.elem_id = variaz_stanz_anno1.elem_id
    LEFT JOIN variaz_stanz_anno2 on capitoli.elem_id = variaz_stanz_anno2.elem_id
    LEFT JOIN variaz_cassa_anno on capitoli.elem_id = variaz_cassa_anno.elem_id
    LEFT JOIN variaz_residui_anno on capitoli.elem_id = variaz_residui_anno.elem_id;

delete from siac_rep_var_spese where utente=user_table;

raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
	when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;            
	when others  THEN
        RTN_MESSAGGIO:='Ricerca dati capitolo';
		 RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

--SIAC-8284 - Maurizio - FINE




--SIAC-8288 - Haitham - INIZIO 
DROP VIEW siac.siac_v_dwh_variazione_bilancio;

CREATE OR REPLACE VIEW siac.siac_v_dwh_variazione_bilancio
AS SELECT tb.bil_anno,
    tb.numero_variazione,
    tb.desc_variazione,
    tb.cod_stato_variazione,
    tb.desc_stato_variazione,
    tb.cod_tipo_variazione,
    tb.desc_tipo_variazione,
    tb.anno_atto_amministrativo,
    tb.numero_atto_amministrativo,
    tb.cod_tipo_atto_amministrativo,
    tb.oggetto_atto_amministrativo,
    tb.cod_capitolo,
    tb.cod_articolo,
    tb.cod_ueb,
    tb.cod_tipo_capitolo,
    tb.importo,
    tb.tipo_importo,
    tb.anno_variazione,
    tb.attoamm_id,
    tb.ente_proprietario_id,
    tb.cod_sac,
    tb.desc_sac,
    tb.tipo_sac,
    tb.data_definizione,
    tb.data_apertura_proposta,
    tb.data_chiusura_proposta,
    tb.cod_sac_proposta,
    tb.desc_sac_proposta,
    tb.tipo_sac_proposta
   FROM ( WITH variaz AS (
                 SELECT p.anno AS bil_anno,
                    e.variazione_num AS numero_variazione,
                    e.variazione_desc AS desc_variazione,
                    d.variazione_stato_tipo_code AS cod_stato_variazione,
                    d.variazione_stato_tipo_desc AS desc_stato_variazione,
                    f.variazione_tipo_code AS cod_tipo_variazione,
                    f.variazione_tipo_desc AS desc_tipo_variazione,
                    a.elem_code AS cod_capitolo,
                    a.elem_code2 AS cod_articolo,
                    a.elem_code3 AS cod_ueb,
                    i.elem_tipo_code AS cod_tipo_capitolo,
                    b.elem_det_importo AS importo,
                    h.elem_det_tipo_desc AS tipo_importo,
                    l.anno AS anno_variazione,
                    c.attoamm_id,
                    a.ente_proprietario_id,
                        CASE
                            WHEN d.variazione_stato_tipo_code::text = 'D'::text THEN c.validita_inizio
                            ELSE NULL::timestamp without time zone
                        END AS data_definizione,
                    e.data_apertura_proposta,
                    e.data_chiusura_proposta,
                    e.classif_id
                   FROM siac_t_bil_elem a,
                    siac_t_bil_elem_det_var b,
                    siac_r_variazione_stato c,
                    siac_d_variazione_stato d,
                    siac_t_variazione e,
                    siac_d_variazione_tipo f,
                    siac_t_bil g,
                    siac_d_bil_elem_det_tipo h,
                    siac_d_bil_elem_tipo i,
                    siac_t_periodo l,
                    siac_t_periodo p
                  WHERE a.elem_id = b.elem_id AND c.variazione_stato_id = b.variazione_stato_id AND c.variazione_stato_tipo_id = d.variazione_stato_tipo_id AND c.variazione_id = e.variazione_id AND f.variazione_tipo_id = e.variazione_tipo_id AND b.data_cancellazione IS NULL AND a.data_cancellazione IS NULL AND c.data_cancellazione IS NULL AND g.bil_id = e.bil_id AND h.elem_det_tipo_id = b.elem_det_tipo_id AND i.elem_tipo_id = a.elem_tipo_id AND l.periodo_id = b.periodo_id AND p.periodo_id = g.periodo_id
                ), attoamm AS (
                 SELECT m.attoamm_id,
                    m.attoamm_anno AS anno_atto_amministrativo,
                    m.attoamm_numero AS numero_atto_amministrativo,
                    q.attoamm_tipo_code AS cod_tipo_atto_amministrativo,
                    m.attoamm_oggetto AS oggetto_atto_amministrativo
                   FROM siac_t_atto_amm m,
                    siac_d_atto_amm_tipo q
                  WHERE q.attoamm_tipo_id = m.attoamm_tipo_id AND m.data_cancellazione IS NULL AND q.data_cancellazione IS NULL
                ), sac AS (
                 SELECT i.attoamm_id,
                    l.classif_id,
                    l.classif_code,
                    l.classif_desc,
                    m.classif_tipo_code
                   FROM siac_r_atto_amm_class i,
                    siac_t_class l,
                    siac_d_class_tipo m,
                    siac_r_class_fam_tree n,
                    siac_t_class_fam_tree o,
                    siac_d_class_fam p
                  WHERE i.classif_id = l.classif_id AND m.classif_tipo_id = l.classif_tipo_id AND n.classif_id = l.classif_id AND n.classif_fam_tree_id = o.classif_fam_tree_id AND o.classif_fam_id = p.classif_fam_id AND p.classif_fam_code::text = '00005'::text AND i.data_cancellazione IS NULL AND l.data_cancellazione IS NULL AND n.data_cancellazione IS NULL
                ), str_proposta AS (
                 SELECT tipo.classif_tipo_code,
                    c.classif_code,
                    c.classif_desc,
                    c.classif_id
                   FROM siac_t_class c,
                    siac_d_class_tipo tipo
                  WHERE (tipo.classif_tipo_code::text = ANY (ARRAY['CDC'::character varying::text, 'CDR'::character varying::text])) AND c.classif_tipo_id = tipo.classif_tipo_id AND c.data_cancellazione IS NULL
                )
         SELECT variaz.bil_anno,
            variaz.numero_variazione,
            variaz.desc_variazione,
            variaz.cod_stato_variazione,
            variaz.desc_stato_variazione,
            variaz.cod_tipo_variazione,
            variaz.desc_tipo_variazione,
            attoamm.anno_atto_amministrativo,
            attoamm.numero_atto_amministrativo,
            attoamm.cod_tipo_atto_amministrativo,
            attoamm.oggetto_atto_amministrativo,
            variaz.cod_capitolo,
            variaz.cod_articolo,
            variaz.cod_ueb,
            variaz.cod_tipo_capitolo,
            variaz.importo,
            variaz.tipo_importo,
            variaz.anno_variazione,
            variaz.attoamm_id,
            variaz.ente_proprietario_id,
            sac.classif_code AS cod_sac,
            sac.classif_desc AS desc_sac,
            sac.classif_tipo_code AS tipo_sac,
            variaz.data_definizione,
            variaz.data_apertura_proposta,
            variaz.data_chiusura_proposta,
            str_proposta.classif_code AS cod_sac_proposta,
            str_proposta.classif_desc AS desc_sac_proposta,
            str_proposta.classif_tipo_code AS tipo_sac_proposta
           FROM variaz
             LEFT JOIN attoamm ON variaz.attoamm_id = attoamm.attoamm_id
             LEFT JOIN sac ON variaz.attoamm_id = sac.attoamm_id
             LEFT JOIN str_proposta ON variaz.classif_id = str_proposta.classif_id) tb
  ORDER BY tb.ente_proprietario_id, tb.bil_anno, tb.numero_variazione;
  
--SIAC-8288 - Haitham - FINE
  
--SIAC-8214 e SIAC-8256 e SIAC-8180
CREATE OR REPLACE FUNCTION siac.fnc_siac_totale_ordinativi_su_residui (
  id_in integer,
  tipo_ord_in varchar
)
RETURNS numeric AS
$body$
DECLARE

-- constant
/*TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_EG constant varchar:='CAP-EG';*/
NVL_STR     constant varchar:='';

TIPO_ORD_P constant varchar:='P';
TIPO_ORD_I constant varchar:='I';

STATO_A     constant varchar:='A';
IMPORTO_ATT constant varchar:='A';

tipoCapitolo varchar(10):=null;
strMessaggio varchar(1500):=NVL_STR;
totOrdinativi numeric:=0;

ordTipoId integer:=0;
enteProprietarioId integer :=0;
ordTsDetTipoId integer:=0;
ordStatoId integer:=0;
bilancioId integer:=0;
ordTsId integer:=0;

ordRecId record;
curImportoOrd numeric:=0;

BEGIN

 strMessaggio:='Calcolo totale ordinativi su residui per elem_id='||id_in||'.';

 curImportoOrd :=0;
   
   select coalesce(sum(d.ord_ts_det_importo),0)  into curImportoOrd
   from 
	siac_r_ordinativo_bil_elem a, siac_t_ordinativo b, siac_t_ordinativo_ts c,
	siac_t_ordinativo_ts_det d,siac_r_ordinativo_stato e,siac_d_ordinativo_stato f
	, siac_d_ordinativo_tipo g,
	siac_d_ordinativo_ts_det_tipo h
	where a.ord_id=b.ord_id
	and c.ord_id=b.ord_id
	and d.ord_ts_id=c.ord_ts_id
	and e.ord_id=b.ord_id
	and e.ord_stato_id=f.ord_stato_id
	and f.ord_stato_code<>STATO_A
	and g.ord_tipo_id=b.ord_tipo_id
	and g.ord_tipo_code=tipo_ord_in
	and a.elem_id=id_in
	and h.ord_ts_det_tipo_id=d.ord_ts_det_tipo_id
	and h.ord_ts_det_tipo_code=IMPORTO_ATT
	and   now() between a.validita_inizio and COALESCE(a.validita_fine,now())
	and   now() between e.validita_inizio and COALESCE(e.validita_fine,now())
	and a.data_cancellazione is null
	and b.data_cancellazione is null
	and c.data_cancellazione is null
	and d.data_cancellazione is null
	and e.data_cancellazione is null
	and f.data_cancellazione is null
	and g.data_cancellazione is null
	and h.data_cancellazione is null
	and (exists (
		select 1 from siac_r_liquidazione_ord srlo,
		siac_r_liquidazione_movgest srlm,
		siac_t_movgest_ts stmt, siac_t_movgest stm, siac_t_bil stb, siac_t_periodo stp 
		where srlm.liq_id  = srlo.liq_id 
		and stmt.movgest_ts_id  = srlm.movgest_ts_id 
		and stm.movgest_id  = stmt.movgest_id 
		and srlo.sord_id  = c.ord_ts_id
		and stb.bil_id = stm.bil_id
		and stb.periodo_id  = stp.periodo_id 
		and   now() between stm.validita_inizio and COALESCE(stm.validita_fine,now())
		and   now() between stmt.validita_inizio and COALESCE(stmt.validita_fine,now())
		and   now() between srlo.validita_inizio and COALESCE(srlo.validita_fine,now())
		and   now() between srlm.validita_inizio and COALESCE(srlm.validita_fine,now())
		and srlm.data_cancellazione  is null 
		and srlo.data_cancellazione  is null
		and stm.data_cancellazione  is null 
		and stmt.data_cancellazione  is null
		and stm.movgest_anno::integer < stp.anno::integer
	) or exists (
		select 1 from siac_r_ordinativo_ts_movgest_ts srotmt,
		siac_t_movgest_ts stmt, siac_t_movgest stm, siac_t_bil stb, siac_t_periodo stp 
		where stmt.movgest_ts_id  = srotmt.movgest_ts_id 
		and stm.movgest_id  = stmt.movgest_id 
		and srotmt.ord_ts_id  = c.ord_ts_id
		and stb.bil_id = stm.bil_id
		and stb.periodo_id  = stp.periodo_id 
		and   now() between stm.validita_inizio and COALESCE(stm.validita_fine,now())
		and   now() between stmt.validita_inizio and COALESCE(stmt.validita_fine,now())
		and   now() between srotmt.validita_inizio and COALESCE(srotmt.validita_fine,now())
		and srotmt.data_cancellazione  is null 
		and stm.data_cancellazione  is null 
		and stmt.data_cancellazione  is null
		and stm.movgest_anno::integer < stp.anno::integer
		)
	
	);



   totOrdinativi:=totOrdinativi+curImportoOrd;


 return totOrdinativi;


exception
   when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        totOrdinativi:=0;
        return totOrdinativi;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        totOrdinativi:=0;
        return totOrdinativi;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

CREATE OR REPLACE FUNCTION siac.fnc_siac_totalepagatougresidui (
  id_in integer
)
RETURNS numeric AS
$body$
DECLARE

TIPO_ORD_P constant varchar:='P';
totPagato numeric:=0;
strMessaggio varchar(1500):=null;

BEGIN

strMessaggio:='Totale pagato per elem_id='||id_in||'.';


totPagato:=fnc_siac_totale_ordinativi_su_residui(id_in,TIPO_ORD_P);


return totPagato;


exception
   when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        totPagato:=0;
        return totPagato;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        totPagato:=0;
        return totOrdinativi;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;
  
--SIAC-8214 e SIAC-8256 e SIAC-8180


--SIAC-8295 - Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR066_prime_note_integrate" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_data_reg_da date,
  p_data_reg_a date,
  p_num_prima_nota integer,
  p_num_prima_nota_def integer,
  p_tipologia varchar,
  p_tipo_evento varchar,
  p_evento varchar
)
RETURNS TABLE (
  nome_ente varchar,
  num_movimento varchar,
  cod_beneficiario varchar,
  ragione_sociale varchar,
  num_capitolo varchar,
  num_articolo varchar,
  ueb varchar,
  classif_bilancio varchar,
  imp_movimento numeric,
  descr_movimento varchar,
  num_prima_nota integer,
  data_registrazione date,
  stato_prima_nota varchar,
  descr_prima_nota varchar,
  cod_causale varchar,
  num_riga integer,
  cod_conto varchar,
  descr_riga varchar,
  importo_dare numeric,
  importo_avere numeric,
  key_movimento integer,
  evento_tipo_code varchar,
  evento_code varchar,
  causale_ep_tipo_code varchar,
  pnota_stato_code varchar,
  num_prima_nota_def integer,
  data_registrazione_def date
) AS
$body$
DECLARE
elenco_prime_note record;
dati_movimento record;
elenco_tipo_classif record;
dati_classif	record;
idMacroAggreg	integer;
idProgramma		integer;
idCategoria		integer;
prec_num_prima_nota integer;
prec_num_movimento_key integer;
prec_num_movimento varchar;
prec_num_capitolo varchar;
prec_num_articolo varchar;
prec_ueb varchar;
prec_descr_movimento varchar;
prec_cod_beneficiario varchar;
prec_ragione_sociale varchar;
prec_imp_movimento numeric;
prec_classif_bilancio varchar;


DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO 		varchar(1000):=DEF_NULL;
user_table			varchar;
v_fam_missioneprogramma varchar;
v_fam_titolomacroaggregato varchar;
sub_impegno VARCHAR;
soggetto_code_mod VARCHAR;
soggetto_desc_mod VARCHAR;

BEGIN
	nome_ente='';
    num_movimento='';
    cod_beneficiario='';
    ragione_sociale='';
    num_capitolo='';
    num_articolo='';
    ueb='';
    classif_bilancio='';
    imp_movimento=0;
    descr_movimento='';
    num_prima_nota=0;
    num_prima_nota_def=0;
    data_registrazione=NULL;
    data_registrazione_def=NULL;
    stato_prima_nota='';
    descr_prima_nota='';
    cod_causale='';
    num_riga=0;
    cod_conto='';
    descr_riga='';
    importo_dare=0;
    importo_avere=0;
    key_movimento=0;
    evento_tipo_code='';
    evento_code='';
    causale_ep_tipo_code='';
    pnota_stato_code='';
    
    prec_num_prima_nota=0;
	prec_num_movimento_key =0;
	prec_num_movimento ='';
    prec_descr_movimento='';
    prec_num_capitolo='';
	prec_num_articolo='';
    prec_ueb='';
    prec_cod_beneficiario='';
    prec_ragione_sociale='';
    prec_imp_movimento=0;
    prec_classif_bilancio='';
    
	v_fam_missioneprogramma :='00001';
	v_fam_titolomacroaggregato := '00002';
    sub_impegno='';
    soggetto_code_mod='';
    soggetto_desc_mod='';
    
    select fnc_siac_random_user()
	into	user_table;
	
    /* carico su una tabella temporanea i dati della struttura dei capitolo di spesa */
/*insert into siac_rep_mis_pro_tit_mac_riga_anni
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

-- 05/09/2016: sostituita la query di caricamento struttura del bilancio
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
    /* 02/09/2016: start filtro per mis-prog-macro*/
   -- , siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
  /* 02/09/2016: start filtro per mis-prog-macro*/
 --AND programma.programma_id = progmacro.classif_a_id
-- AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/ 
 and titusc.ente_proprietario_id=missione.ente_proprietario_id;
 


    /* carico su una tabella temporanea i dati della struttura dei capitolo di entrata */
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

	/* estrazione dei dati delle prime note */
    

--if (p_data_reg_da is NULL OR p_data_reg_a is NULL)  THEN	    
    for elenco_prime_note IN
    select  ente_prop.ente_denominazione	nome_ente,
        r_ev_reg_movfin.campo_pk_id 	key_movimento,
        tipo_evento.evento_tipo_code, d_tipo_causale.causale_ep_tipo_code,  
        evento.evento_code,d_coll_tipo.collegamento_tipo_code,
        prima_nota.pnota_numero num_prima_nota, prima_nota.pnota_desc,prima_nota.pnota_data, 
        pnota_stato.pnota_stato_code, prima_nota.pnota_progressivogiornale num_prima_nota_def,
            pnota_stato.pnota_stato_desc,pdce_conto.pdce_conto_code codice_conto,
            pdce_conto.pdce_conto_desc descr_riga,
            prima_nota.pnota_dataregistrazionegiornale pnota_data_def,
             causale_ep.causale_ep_code cod_causale, causale_ep.causale_ep_desc, mov_ep.movep_code,
            mov_ep.movep_desc, mov_ep_det.movep_det_code num_riga, mov_ep_det.movep_det_desc,
            mov_ep_det.movep_det_segno, mov_ep_det.movep_det_importo
    from siac_t_ente_proprietario	ente_prop,
            siac_t_periodo	 		anno_eserc,	
            siac_t_bil	 			bilancio,
            siac_t_prima_nota prima_nota,
              --23/07/2021 SIAC-8295.
              -- Aggiunto il filtro sull'ambito FIN            
            siac_d_ambito amb,
            siac_t_mov_ep_det	mov_ep_det,
            siac_r_prima_nota_stato r_pnota_stato,
            siac_d_prima_nota_stato pnota_stato,
            siac_t_pdce_conto	pdce_conto,
            siac_t_causale_ep	causale_ep,
            siac_d_causale_ep_tipo d_tipo_causale,
            siac_t_mov_ep		mov_ep
            LEFT JOIN siac_t_reg_movfin	reg_movfin
            on (reg_movfin.regmovfin_id=mov_ep.regmovfin_id 
            	AND reg_movfin.data_cancellazione IS NULL) 
            LEFT JOIN siac_r_evento_reg_movfin  r_ev_reg_movfin        
            on (r_ev_reg_movfin.regmovfin_id=reg_movfin.regmovfin_id 
            	and r_ev_reg_movfin.data_cancellazione IS NULL)
            LEFT JOIN siac_d_evento		evento
            on (evento.evento_id=r_ev_reg_movfin.evento_id
            	AND evento.data_cancellazione IS NULL)
            LEFT JOIN siac_d_evento_tipo	tipo_evento
            on (tipo_evento.evento_tipo_id=evento.evento_tipo_id
            	AND tipo_evento.data_cancellazione IS NULL)  
            LEFT JOIN siac_d_collegamento_tipo    d_coll_tipo 
            on (d_coll_tipo.collegamento_tipo_id=evento.collegamento_tipo_id
            	and  d_coll_tipo.data_cancellazione is NULL) 
    where bilancio.periodo_id=anno_eserc.periodo_id
            and anno_eserc.ente_proprietario_id=ente_prop.ente_proprietario_id	
            and prima_nota.bil_id=bilancio.bil_id
            and prima_nota.ente_proprietario_id=ente_prop.ente_proprietario_id
            -- QUALE JOIN è corretto???
             and prima_nota.pnota_id=mov_ep.regep_id
            -- QUALE JOIN è corretto??? and prima_nota.pnota_id=mov_ep.regmovfin_id
            and mov_ep.movep_id=mov_ep_det.movep_id
            and r_pnota_stato.pnota_id=prima_nota.pnota_id
            and pnota_stato.pnota_stato_id=r_pnota_stato.pnota_stato_id
            and pdce_conto.pdce_conto_id=mov_ep_det.pdce_conto_id
            and causale_ep.causale_ep_id=mov_ep.causale_ep_id
            and d_tipo_causale.causale_ep_tipo_id=causale_ep.causale_ep_tipo_id 
            and amb.ambito_id=prima_nota.ambito_id
            and ente_prop.ente_proprietario_id=p_ente_prop_id   
            and anno_eserc.anno=p_anno 
            AND (((p_data_reg_da is NULL OR p_data_reg_a is NULL) 
            	OR (p_data_reg_da is NOT NULL AND p_data_reg_a is NOT NULL 
                	AND prima_nota.pnota_data BETWEEN p_data_reg_da ::timestamp AND (p_data_reg_a+1) ::timestamp))
 			/* 30/01/2017: il filtro sulle date avviene anche sulla data definitiva */
              OR ((p_data_reg_da is NULL OR p_data_reg_a is NULL) 
            	OR (p_data_reg_da is NOT NULL AND p_data_reg_a is NOT NULL 
                	AND (prima_nota.pnota_dataregistrazionegiornale is not null 
                     AND prima_nota.pnota_dataregistrazionegiornale BETWEEN p_data_reg_da ::timestamp AND (p_data_reg_a+1) ::timestamp))))                    
            /* 24/01/2017: aggiunto filtro sul numero provvisorio della prima nota */
            AND (p_num_prima_nota IS NULL OR (p_num_prima_nota IS NOT NULL    
            					AND prima_nota.pnota_numero =  p_num_prima_nota)) 
 			/* 24/01/2017: aggiunto filtro sul numero definitivo della prima nota */
            AND (p_num_prima_nota_def IS NULL OR (p_num_prima_nota_def IS NOT NULL    
            					AND prima_nota.pnota_progressivogiornale =  p_num_prima_nota_def))                                                     
			/* 30/01/2017: spostati nella procedura i filtri che prima erano sul report */
            AND ((trim(p_tipologia) <> 'Tutte' AND d_tipo_causale.causale_ep_tipo_code =p_tipologia) OR
            	(trim(p_tipologia) = 'Tutte'))
            AND ((trim(p_tipo_evento) <> 'Tutti' AND tipo_evento.evento_tipo_code =p_tipo_evento) OR
            	(trim(p_tipo_evento) = 'Tutti'))                   
            AND ((trim(p_evento) <> 'Tutti' AND  evento.evento_code = p_evento)  OR
					(trim(p_evento) = 'Tutti' ))            
            AND pnota_stato.pnota_stato_code <> 'A'  
              --23/07/2021 SIAC-8295.
              -- Aggiunto il filtro sull'ambito FIN            
            and amb.ambito_code='AMBITO_FIN'     
            and ente_prop.data_cancellazione is NULL
            and bilancio.data_cancellazione is NULL
            and anno_eserc.data_cancellazione is NULL
            and prima_nota.data_cancellazione is NULL
            and mov_ep.data_cancellazione is NULL
            and mov_ep_det.data_cancellazione is NULL
            and r_pnota_stato.data_cancellazione is NULL
            and pnota_stato.data_cancellazione is NULL
            and pdce_conto.data_cancellazione is NULL
            and causale_ep.data_cancellazione is NULL
            and d_tipo_causale.data_cancellazione is NULL
            ORDER BY num_prima_nota,  num_riga

        
            loop
            
            nome_ente=elenco_prime_note.nome_ente;    	    	
            num_prima_nota=elenco_prime_note.num_prima_nota;
            num_prima_nota_def= COALESCE(elenco_prime_note.num_prima_nota_def,0);
            data_registrazione=elenco_prime_note.pnota_data;
            data_registrazione_def=elenco_prime_note.pnota_data_def;
            stato_prima_nota=elenco_prime_note.pnota_stato_desc;
            descr_prima_nota=elenco_prime_note.pnota_desc;
            cod_causale=elenco_prime_note.cod_causale;
            num_riga=elenco_prime_note.num_riga::INTEGER;
            cod_conto=elenco_prime_note.codice_conto;
            descr_riga=elenco_prime_note.descr_riga;
            key_movimento=elenco_prime_note.key_movimento;
            evento_tipo_code=elenco_prime_note.evento_tipo_code;
            evento_code=elenco_prime_note.evento_code;
            causale_ep_tipo_code=elenco_prime_note.causale_ep_tipo_code;
            pnota_stato_code=elenco_prime_note.pnota_stato_code;
            
            if upper(elenco_prime_note.movep_det_segno)='AVERE' THEN                
                  importo_dare=0;
                  importo_avere=elenco_prime_note.movep_det_importo;
                
            ELSE                
                  importo_dare=elenco_prime_note.movep_det_importo;
                  importo_avere=0;                            
            end if;
                /* Tipo Impegno o Tipo Accertamento */
raise notice 'Gestisco tipo_code = %, evento_code =%, collegamento_code =%',
	           elenco_prime_note.evento_tipo_code, elenco_prime_note.evento_code,
                elenco_prime_note.collegamento_tipo_code;  
raise notice 'CHIAVE MOV = %, NUM PN PROVV = %',   elenco_prime_note.key_movimento,elenco_prime_note.num_prima_nota;                  
--raise notice 'Tipo: %. Num mov % (prec %). numPnota % (prec %)',elenco_prime_note.evento_tipo_code, elenco_prime_note.key_movimento,prec_num_movimento_key, elenco_prime_note.num_prima_nota,prec_num_prima_nota;               
            if elenco_prime_note.evento_tipo_code='I' OR
                    elenco_prime_note.evento_tipo_code='A' THEN				                 
                
                    /* se il record precedente aveva gli stessi dati, non eseguo di nuovo la query */                                  
                  if prec_num_movimento_key=elenco_prime_note.key_movimento AND 
                      prec_num_prima_nota=elenco_prime_note.num_prima_nota THEN
                      num_movimento=prec_num_movimento;
                      num_capitolo=prec_num_capitolo;
                      num_articolo=prec_num_articolo;
                      ueb=prec_ueb;
                      descr_movimento=prec_descr_movimento;
                      cod_beneficiario=prec_cod_beneficiario;
                      ragione_sociale=prec_ragione_sociale;
                      imp_movimento=prec_imp_movimento;
                      classif_bilancio=prec_classif_bilancio;

                     -- raise notice 'Esiste già %',classif_bilancio;
                  ELSE
                    	/* impegno o accertamento: devo andare sulla tabella
                        	siac_t_movgest 
                           Devo testare tutti i possibili codici!!*/	
                        raise notice 'Evento %', elenco_prime_note.evento_code;
                   /* if elenco_prime_note.evento_code = 'IMP-INS' OR
                    	elenco_prime_note.evento_code = 'MIM-INS-I' OR
                        elenco_prime_note.evento_code = 'MIM-INS-S' OR
                        elenco_prime_note.evento_code = 'IMP-PRG' OR
                    	elenco_prime_note.evento_code = 'ACC-INS' OR
                        elenco_prime_note.evento_code = 'MAC-ANN' OR
                        elenco_prime_note.evento_code = 'MAC-INS-I' OR
                        elenco_prime_note.evento_code = 'MAC-INS-S' THEN  */   
                  -- raise notice 'COLL_TIPO = %', elenco_prime_note.collegamento_tipo_code;
                  -- raise notice 'tipo_EVENTO = %', elenco_prime_note.evento_tipo_code;
                    if elenco_prime_note.collegamento_tipo_code in('I','A') THEN                                                                  
                        SELECT movgest.movgest_numero, movgest.movgest_desc,movgest.movgest_anno,
                            bil_elem.elem_code cod_capitolo, bil_elem.elem_code2 num_articolo,bil_elem.elem_id,
                            bil_elem.elem_code3 ueb, soggetto.soggetto_desc, soggetto.soggetto_code,
                            ts_det_movgest.movgest_ts_det_importo imp_movimento,
                            d_soggetto_classe.soggetto_classe_desc,
                            d_soggetto_classe.soggetto_classe_code
                            INTO dati_movimento 
                              from siac_t_movgest movgest,                         
                               siac_t_movgest_ts_det ts_det_movgest,
                               siac_r_movgest_bil_elem  r_movgest_bil_elem,
                               siac_t_bil_elem		bil_elem,
                               siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
                                siac_t_movgest_ts	ts_movgest                      
                               LEFT join siac_r_movgest_ts_sog	r_mov_gest_ts_sog
                              on (r_mov_gest_ts_sog.movgest_ts_id=ts_movgest.movgest_ts_id and r_mov_gest_ts_sog.data_cancellazione is NULL)  
                              LEFT join siac_t_soggetto		soggetto
                              on (soggetto.soggetto_id=r_mov_gest_ts_sog.soggetto_id 
                              	and soggetto.data_cancellazione is NULL)  
                              LEFT JOIN siac_r_movgest_ts_sogclasse r_movgest_ts_sogclasse
                             on (r_movgest_ts_sogclasse.movgest_ts_id=ts_movgest.movgest_ts_id
                                 AND r_movgest_ts_sogclasse.data_cancellazione IS NULL)
                            LEFT JOIN siac_d_soggetto_classe d_soggetto_classe
                                on (d_soggetto_classe.soggetto_classe_id=r_movgest_ts_sogclasse.soggetto_classe_id
                                and d_soggetto_classe.data_cancellazione IS NULL)
                              where ts_movgest.movgest_id=movgest.movgest_id
                              and ts_det_movgest.movgest_ts_id=  ts_movgest.movgest_ts_id
                              and d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=ts_det_movgest.movgest_ts_det_tipo_id
                              and r_movgest_bil_elem.movgest_id=movgest.movgest_id
                              and bil_elem.elem_id=r_movgest_bil_elem.elem_id
                              and movgest.movgest_id= elenco_prime_note.key_movimento
                              and bil_elem.ente_proprietario_id=p_ente_prop_id
                              and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                              and movgest.data_cancellazione is null
                              and ts_movgest.data_cancellazione is null
                              and ts_det_movgest.data_cancellazione is null
                              and r_movgest_bil_elem.data_cancellazione is null
                              and bil_elem.data_cancellazione is null
                              and d_movgest_ts_det_tipo.data_cancellazione is null;                          
                        IF NOT FOUND THEN
                        	/* 25/02/2016: se non esiste il movimento non interrompo la procedura */
                           -- RAISE EXCEPTION 'Impegno/accertamento senza Periodo. Non esiste il movimento %', elenco_prime_note.key_movimento;
                           -- return;
                        	descr_movimento='Non esiste il movimento';	                  
                        END IF;
                        sub_impegno='';
                        soggetto_code_mod='';
    					soggetto_desc_mod='';
                        	-- SubImpegno o SubAccertamento
                    ELSIF elenco_prime_note.collegamento_tipo_code in('SI','SA') THEN                     
						SELECT movgest.movgest_numero, movgest.movgest_desc,movgest.movgest_anno,
                            bil_elem.elem_code cod_capitolo, bil_elem.elem_code2 num_articolo,bil_elem.elem_id,
                            bil_elem.elem_code3 ueb, soggetto.soggetto_desc, soggetto.soggetto_code,
                            ts_det_movgest.movgest_ts_det_importo imp_movimento, ts_movgest.movgest_ts_code,
                            d_soggetto_classe.soggetto_classe_desc,
                            d_soggetto_classe.soggetto_classe_code
                            INTO dati_movimento 
                              from siac_t_movgest movgest,                         
                               siac_t_movgest_ts_det ts_det_movgest,
                               siac_r_movgest_bil_elem  r_movgest_bil_elem,
                               siac_t_bil_elem		bil_elem,
                               siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
                                siac_t_movgest_ts	ts_movgest                      
                              LEFT join siac_r_movgest_ts_sog	r_mov_gest_ts_sog
                              on (r_mov_gest_ts_sog.movgest_ts_id=ts_movgest.movgest_ts_id and r_mov_gest_ts_sog.data_cancellazione is NULL)  
                              LEFT join siac_t_soggetto		soggetto
                              on (soggetto.soggetto_id=r_mov_gest_ts_sog.soggetto_id 
                              	and soggetto.data_cancellazione is NULL)  
                              LEFT JOIN siac_r_movgest_ts_sogclasse r_movgest_ts_sogclasse
                             on (r_movgest_ts_sogclasse.movgest_ts_id=ts_movgest.movgest_ts_id
                                 AND r_movgest_ts_sogclasse.data_cancellazione IS NULL)
                            LEFT JOIN siac_d_soggetto_classe d_soggetto_classe
                                on (d_soggetto_classe.soggetto_classe_id=r_movgest_ts_sogclasse.soggetto_classe_id
                                and d_soggetto_classe.data_cancellazione IS NULL)
                              where ts_movgest.movgest_id=movgest.movgest_id
                              and ts_det_movgest.movgest_ts_id=  ts_movgest.movgest_ts_id
                              and d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=ts_det_movgest.movgest_ts_det_tipo_id
                              and r_movgest_bil_elem.movgest_id=movgest.movgest_id
                              and bil_elem.elem_id=r_movgest_bil_elem.elem_id
                              /* Accedo alla tabella della testata per
                              	sub-impegno e sub-accertamento */
                              --and movgest.movgest_id= elenco_prime_note.key_movimento
                              and ts_movgest.movgest_ts_id= elenco_prime_note.key_movimento
                              and bil_elem.ente_proprietario_id=p_ente_prop_id
                              and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                              and movgest.data_cancellazione is null
                              and ts_movgest.data_cancellazione is null
                              and ts_det_movgest.data_cancellazione is null
                              and r_movgest_bil_elem.data_cancellazione is null
                              and bil_elem.data_cancellazione is null
                              and d_movgest_ts_det_tipo.data_cancellazione is null;                          
                        IF NOT FOUND THEN
                        /* 25/02/2016: se non esiste il movimento non interrompo la procedura */
                           -- RAISE EXCEPTION 'Sub-Impegno/Sub-Accertamento senza Periodo. Non esiste il movimento %', elenco_prime_note.key_movimento;
                           -- return;
                           descr_movimento='Non esiste il movimento';
                        ELSE 
                        	sub_impegno= COALESCE(dati_movimento.movgest_ts_code,'');
                            soggetto_code_mod='';
    					    soggetto_desc_mod='';
                        END IF;     
                    ELSIF elenco_prime_note.collegamento_tipo_code in('MMGS','MMGE') THEN      
                    raise notice 'TIPO_CODE = % - KEY = %', elenco_prime_note.collegamento_tipo_code,elenco_prime_note.key_movimento;
                                      
                  SELECT t_modifica.mod_id,r_modifica_stato.mod_stato_id, movgest.movgest_numero, movgest.movgest_desc,movgest.movgest_anno,
                          bil_elem.elem_code cod_capitolo, bil_elem.elem_code2 num_articolo,bil_elem.elem_id,
                          bil_elem.elem_code3 ueb, 
                          soggetto.soggetto_desc, soggetto.soggetto_code,
                          soggetto_mod.soggetto_desc desc_sogg_mod,
                          soggetto_mod.soggetto_code code_sogg_mod,
                          d_soggetto_classe.soggetto_classe_desc,
                          d_soggetto_classe.soggetto_classe_code,
                          ts_det_movgest.movgest_ts_det_importo imp_movimento, ts_movgest.movgest_ts_code                            
                            INTO dati_movimento
                            from siac_t_movgest movgest,                         
                             siac_t_movgest_ts_det ts_det_movgest,
                             siac_r_movgest_bil_elem  r_movgest_bil_elem,
                             siac_t_bil_elem		bil_elem,
                             siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,            
                             siac_t_movgest_ts	ts_movgest   
                             LEFT join siac_r_movgest_ts_sog	r_mov_gest_ts_sog
                            on (r_mov_gest_ts_sog.movgest_ts_id=ts_movgest.movgest_ts_id 
                            and r_mov_gest_ts_sog.data_cancellazione is NULL) 
                            LEFT join siac_t_soggetto		soggetto
                            on (soggetto.soggetto_id=r_mov_gest_ts_sog.soggetto_id         	
                             and soggetto.data_cancellazione is NULL) 
                             LEFT JOIN siac_r_movgest_ts_sog_mod r_movgest_ts_sog_mod
                             on (r_movgest_ts_sog_mod.movgest_ts_id=ts_movgest.movgest_ts_id
                              AND  r_movgest_ts_sog_mod.data_cancellazione IS NULL)  
                             LEFT join siac_t_soggetto		soggetto_mod
                            on (soggetto_mod.soggetto_id=r_movgest_ts_sog_mod.soggetto_id_new          	
                             and soggetto_mod.data_cancellazione is NULL)  
                            LEFT JOIN siac_r_movgest_ts_sogclasse r_movgest_ts_sogclasse
                             on (r_movgest_ts_sogclasse.movgest_ts_id=ts_movgest.movgest_ts_id
                                 AND r_movgest_ts_sogclasse.data_cancellazione IS NULL)
                            LEFT JOIN siac_d_soggetto_classe d_soggetto_classe
                                on (d_soggetto_classe.soggetto_classe_id=r_movgest_ts_sogclasse.soggetto_classe_id
                                and d_soggetto_classe.data_cancellazione IS NULL),
                             siac_t_movgest_ts_det_mod t_movgest_ts_det_mod    
                              LEFT join  siac_r_modifica_stato  r_modifica_stato           
                             ON (t_movgest_ts_det_mod.mod_stato_r_id=r_modifica_stato.mod_stato_r_id
                              and r_modifica_stato.data_cancellazione is null)
                             LEFT JOIN siac_t_modifica t_modifica 
                             on (t_modifica.mod_id=r_modifica_stato.mod_id
                              AND t_modifica.data_cancellazione IS NULL)                           
                  where ts_movgest.movgest_id=movgest.movgest_id
                            and ts_det_movgest.movgest_ts_id=  ts_movgest.movgest_ts_id
                            and d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=ts_det_movgest.movgest_ts_det_tipo_id
                            and r_movgest_bil_elem.movgest_id=movgest.movgest_id
                            and bil_elem.elem_id=r_movgest_bil_elem.elem_id                   
                            and t_movgest_ts_det_mod.movgest_ts_id=  ts_movgest.movgest_ts_id       
                            and t_modifica.mod_id= elenco_prime_note.key_movimento
                            and bil_elem.ente_proprietario_id=p_ente_prop_id
                            and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
                            and movgest.data_cancellazione is null
                            and ts_movgest.data_cancellazione is null
                            and ts_det_movgest.data_cancellazione is null
                            and r_movgest_bil_elem.data_cancellazione is null
                            and bil_elem.data_cancellazione is null
                            and d_movgest_ts_det_tipo.data_cancellazione is null; 
                  		 IF NOT FOUND THEN
                           descr_movimento='Non esiste il movimento';
                         ELSE 
                         	sub_impegno= COALESCE(dati_movimento.movgest_ts_code,'');
                           	soggetto_code_mod=COALESCE(dati_movimento.code_sogg_mod,'');
    						soggetto_desc_mod=COALESCE(dati_movimento.desc_sogg_mod,'');
                         END IF;
                    END IF;
raise notice 'Sogg=%, Sogg_mod=%, Fam_sogg=%', dati_movimento.soggetto_code,  
		soggetto_code_mod, dati_movimento.soggetto_classe_code; 
if soggetto_code_mod <>''then
	raise notice 'SOGGETTO MODIF= X%X',soggetto_code_mod;
end if;
                     
                    	/* 25/02/2016: se non esiste il movimento non carico i dati */
                    if descr_movimento ='' THEN      
                    --raise notice 'SONO SUB-IMPEGNO %/%',dati_movimento.movgest_numero,dati_movimento.movgest_ts_code;             
                        if elenco_prime_note.evento_tipo_code='I' THEN
                            num_movimento=concat('IMP/',dati_movimento.movgest_numero);
                        else
                            num_movimento=concat('ACC/',dati_movimento.movgest_numero);
                        end if;
                        
                        --raise notice 'SUB=%',num_movimento;
                        if sub_impegno  <> '' THEN
                        	num_movimento= concat(num_movimento,'-',sub_impegno);
                        end if;
                        
                        -- raise notice 'SUB=%',num_movimento;
                        num_capitolo=dati_movimento.cod_capitolo;
                        num_articolo=dati_movimento.num_articolo;
                        ueb=dati_movimento.ueb;
                        descr_movimento=dati_movimento.movgest_desc;
                        if soggetto_code_mod <> '' THEN
                        	cod_beneficiario=soggetto_code_mod;
                        else
                        	cod_beneficiario=COALESCE(dati_movimento.soggetto_code,COALESCE(dati_movimento.soggetto_classe_code,''));
                        end if;
                        if soggetto_desc_mod <> '' THEN
                        	ragione_sociale=dati_movimento.soggetto_desc;   
                        else
                        	ragione_sociale=COALESCE(dati_movimento.soggetto_desc,COALESCE(dati_movimento.soggetto_classe_desc,''));
                        end if;
                        imp_movimento=dati_movimento.imp_movimento;

                            
                            /* salvo i dati correnti per il prossimo record delle prime note */
                        prec_num_movimento_key=elenco_prime_note.key_movimento;
                        prec_num_prima_nota=elenco_prime_note.num_prima_nota;
                            
                        prec_num_movimento= num_movimento;
                        prec_num_capitolo=num_capitolo;
                        prec_num_articolo=num_articolo;
                        prec_ueb=ueb;
                        prec_descr_movimento=descr_movimento;
                        prec_cod_beneficiario=cod_beneficiario;
                        prec_ragione_sociale=ragione_sociale;
                        prec_imp_movimento=imp_movimento;

                        
                        if elenco_prime_note.evento_tipo_code='I' THEN
                            /* nel caso degli impegni devo leggere la classificazione delle spese */
                          idProgramma=0;
                          idMacroAggreg=0;
                              /* cerco la classificazione del capitolo.
                                  mi servono solo MACROAGGREGATO e  PROGRAMMA */
                          for elenco_tipo_classif in
                              select class_tipo.classif_tipo_code, classif.classif_id
                              from siac_t_class classif, siac_d_class_tipo class_tipo, 
                                  siac_r_bil_elem_class r_bil_class
                              where classif.classif_tipo_id=class_tipo.classif_tipo_id
                              and classif.classif_id=r_bil_class.classif_id
                              and r_bil_class.elem_id=dati_movimento.elem_id
                              and classif.ente_proprietario_id=p_ente_prop_id
                              and class_tipo.classif_tipo_code IN('MACROAGGREGATO','PROGRAMMA')
                              and classif.data_cancellazione is NULL
                              and class_tipo.data_cancellazione is NULL
                              and r_bil_class.data_cancellazione is NULL
                          loop
                              --raise notice 'Estraggo %',dati_movimento.elem_id;
                              if elenco_tipo_classif.classif_tipo_code='MACROAGGREGATO' THEN
                                  idMacroAggreg = elenco_tipo_classif.classif_id;
                              elsif elenco_tipo_classif.classif_tipo_code='PROGRAMMA' THEN
                                  idProgramma = elenco_tipo_classif.classif_id;
                              end if;                                                          
                              
                          end loop;
                             
                          classif_bilancio='';
                              /* cerco la classificazione del capitolo sulla tabella temporanea */
                          IF idMacroAggreg IS NOT NULL AND idProgramma IS NOT NULL THEN
                            SELECT missione_code||programma_code||'-'||titusc_code||macroag_code  classificazione_bil
                            INTO dati_classif
                            FROM siac_rep_mis_pro_tit_mac_riga_anni a
                            WHERE a.macroag_id = idMacroAggreg AND a.programma_id = idProgramma
                            	and a.ente_proprietario_id=p_ente_prop_id
                                and a.utente=user_table;
                            IF NOT FOUND THEN
                                RAISE notice 'Non esiste la classificazione del capitolo di spesa 1. Elem_id = %. Movimento %. TipoEvento = %. CodeEvento = %', dati_movimento.elem_id, elenco_prime_note.key_movimento, elenco_prime_note.evento_tipo_code, elenco_prime_note.evento_code;
                                --return;
                            ELSE
                                classif_bilancio=dati_classif.classificazione_bil;                    
                                prec_classif_bilancio=classif_bilancio;
                            END IF;
                          else
                            classif_bilancio='';                    
                            prec_classif_bilancio='';
                          end if;
                        else /* evento_code = 'A' */
                          idCategoria=0;
                              /* cerco la classificazione del capitolo.
                                  mi serve solo la CATEGORIA??? */
                          for elenco_tipo_classif in
                              select class_tipo.classif_tipo_code, classif.classif_id
                              from siac_t_class classif, siac_d_class_tipo class_tipo, 
                                  siac_r_bil_elem_class r_bil_class
                              where classif.classif_tipo_id=class_tipo.classif_tipo_id
                              and classif.classif_id=r_bil_class.classif_id
                              and r_bil_class.elem_id=dati_movimento.elem_id
                              and classif.ente_proprietario_id=p_ente_prop_id
                              and class_tipo.classif_tipo_code IN('CATEGORIA')
                              and classif.data_cancellazione is NULL
                              and class_tipo.data_cancellazione is NULL
                              and r_bil_class.data_cancellazione is NULL
                          loop
                              --raise notice 'Estraggo %',dati_movimento.elem_id;
                              if elenco_tipo_classif.classif_tipo_code='CATEGORIA' THEN
                                  idCategoria = elenco_tipo_classif.classif_id;                          
                              end if;                                                          
                              
                          end loop;
                             
                          classif_bilancio='';
                          if idCategoria is not null then
                                  /* cerco la classificazione del capitolo sulla tabella temporanea */
                              SELECT titolo_code||tipologia_code||'-'||categoria_code  classificazione_bil
                              INTO dati_classif
                              FROM siac_rep_tit_tip_cat_riga_anni a
                              WHERE a.categoria_id = idCategoria
                              and a.ente_proprietario_id=p_ente_prop_id
                              and a.utente=user_table;
                              IF NOT FOUND THEN
                                   RAISE notice 'Non esiste la classificazione del capitolo di entrata. Elem_id = %', dati_movimento.elem_id;
                                 -- return;
                              ELSE
                                  classif_bilancio=dati_classif.classificazione_bil;                    
                                  prec_classif_bilancio=classif_bilancio;
                              END IF;        
                          else
                            classif_bilancio='';                    
                            prec_classif_bilancio='';
                          end if;            
                           -- END IF;
                        END IF;
                        
                      end if; 
                  end if; --if descr_movimento ='' THEN
               
                /* evento = Liquidazione */
            elsif  elenco_prime_note.evento_tipo_code='L' THEN
                BEGIN
                    /* se il record precedente aveva gli stessi dati, non eseguo di nuovo la query */                
                  if prec_num_movimento_key=elenco_prime_note.key_movimento AND 
                      prec_num_prima_nota=elenco_prime_note.num_prima_nota THEN
                      num_movimento=prec_num_movimento;
                      num_capitolo=prec_num_capitolo;
                      num_articolo=prec_num_articolo;
                      ueb=prec_ueb;
                      descr_movimento=prec_descr_movimento;
                      cod_beneficiario=prec_cod_beneficiario;
                      ragione_sociale=prec_ragione_sociale;
                      imp_movimento=prec_imp_movimento;
                      classif_bilancio=prec_classif_bilancio;
                     
                     -- raise notice 'Esiste già %',classif_bilancio;
                  ELSE                                       		                      
                        /* record nuovo: estraggo i dati del capitolo */                
                    SELECT liquidazione.liq_numero,   movgest.movgest_numero, movgest.movgest_desc,movgest.movgest_anno,
                        bil_elem.elem_code cod_capitolo, bil_elem.elem_code2 num_articolo,bil_elem.elem_id,
                        bil_elem.elem_code3 ueb, soggetto.soggetto_desc, soggetto.soggetto_code,
                        liquidazione.liq_importo imp_movimento      
                    INTO dati_movimento         
                    FROM siac_t_movgest		movgest,                                            
                        siac_r_liquidazione_movgest  r_liquid_movgest,       	
                        siac_r_movgest_bil_elem  r_movgest_bil_elem,
                        siac_t_bil_elem		bil_elem,
                        siac_t_movgest_ts	ts_movgest,
                        siac_t_liquidazione			liquidazione  
                        LEFT join siac_r_liquidazione_soggetto	r_liquid_ts_sog
                          on (r_liquid_ts_sog.liq_id=liquidazione.liq_id
                          		AND r_liquid_ts_sog.data_cancellazione IS NULL)  
                          LEFT join siac_t_soggetto		soggetto
                          on (soggetto.soggetto_id=r_liquid_ts_sog.soggetto_id
                          	and soggetto.data_cancellazione is NULL)                    
                        WHERE r_movgest_bil_elem.movgest_id=movgest.movgest_id
                          and bil_elem.elem_id=r_movgest_bil_elem.elem_id
                          and liquidazione.liq_id=elenco_prime_note.key_movimento
                          and liquidazione.ente_proprietario_id=p_ente_prop_id
                          and ts_movgest.movgest_id=movgest.movgest_id      
                          and liquidazione.liq_id=r_liquid_movgest.liq_id
                          and r_liquid_movgest.movgest_ts_id=ts_movgest.movgest_ts_id                  
                          and r_movgest_bil_elem.data_cancellazione is NULL
                          and bil_elem.data_cancellazione is NULL
                          and ts_movgest.data_cancellazione is NULL
                          and movgest.data_cancellazione is NULL                                                
                          and liquidazione.data_cancellazione is NULL;
                         -- and r_liquid_movgest.data_cancellazione is NULL;            
                          
                    IF NOT FOUND THEN
                    /* 25/02/2016: se non esiste il movimento non interrompo la procedura */
                       -- RAISE EXCEPTION 'Liquidazione senza Periodo. Non esiste il movimento %', elenco_prime_note.key_movimento;
                       -- return;
                       descr_movimento='Non esiste il movimento';
                    ELSE
                    raise notice ' LIQUID = %', dati_movimento.liq_numero;
                    raise notice 'MOV = %', elenco_prime_note.key_movimento;
                        num_movimento=concat('LIQ/',dati_movimento.liq_numero);
                        num_capitolo=dati_movimento.cod_capitolo;
                        num_articolo=dati_movimento.num_articolo;
                        ueb=dati_movimento.ueb;
                        descr_movimento=dati_movimento.movgest_desc;
                        cod_beneficiario=dati_movimento.soggetto_code;
                        ragione_sociale=dati_movimento.soggetto_desc;   
                        imp_movimento=dati_movimento.imp_movimento;

                            /* salvo i dati correnti per il prossimo record delle prime note */
                        prec_num_movimento_key=elenco_prime_note.key_movimento;
                        prec_num_prima_nota=elenco_prime_note.num_prima_nota;
                        
                        prec_num_movimento= num_movimento;
                        prec_num_capitolo=num_capitolo;
                        prec_num_articolo=num_articolo;
                        prec_ueb=ueb;
                        prec_descr_movimento=descr_movimento;
                        prec_cod_beneficiario=cod_beneficiario;
                        prec_ragione_sociale=ragione_sociale;
                        prec_imp_movimento=imp_movimento;
                        
         
                      idProgramma=0;
                      idMacroAggreg=0;
                          /* cerco la classificazione del capitolo.
                              mi servono solo MACROAGGREGATO e  PROGRAMMA */
                      for elenco_tipo_classif in
                          select class_tipo.classif_tipo_code, classif.classif_id
                          from siac_t_class classif, siac_d_class_tipo class_tipo, 
                              siac_r_bil_elem_class r_bil_class
                          where classif.classif_tipo_id=class_tipo.classif_tipo_id
                          and classif.classif_id=r_bil_class.classif_id
                          and r_bil_class.elem_id=dati_movimento.elem_id
                          and classif.ente_proprietario_id=p_ente_prop_id
                          and class_tipo.classif_tipo_code IN('MACROAGGREGATO','PROGRAMMA')
                          and classif.data_cancellazione is NULL
                          and class_tipo.data_cancellazione is NULL
                          and r_bil_class.data_cancellazione is NULL
                      loop
                          --raise notice 'Estraggo %',dati_movimento.elem_id;
                          if elenco_tipo_classif.classif_tipo_code='MACROAGGREGATO' THEN
                              idMacroAggreg = elenco_tipo_classif.classif_id;
                          elsif elenco_tipo_classif.classif_tipo_code='PROGRAMMA' THEN
                              idProgramma = elenco_tipo_classif.classif_id;
                          end if;                                                          
                          
                      end loop;
                         
                      classif_bilancio='';
                          /* cerco la classificazione del capitolo sulla tabella temporanea */
                      IF idMacroAggreg IS NOT NULL AND idProgramma IS NOT NULL THEN 
                        SELECT missione_code||programma_code||'-'||titusc_code||macroag_code  classificazione_bil
                        INTO dati_classif
                        FROM siac_rep_mis_pro_tit_mac_riga_anni a
                        WHERE macroag_id = idMacroAggreg AND programma_id = idProgramma
                        and a.ente_proprietario_id=p_ente_prop_id
                        and a.utente=user_table;
                        IF NOT FOUND THEN
                             RAISE notice 'Non esiste la classificazione del capitolo di spesa 2. Elem_id = %, MacroAggr %, Programma %', dati_movimento.elem_id, idMacroAggreg, idProgramma;	
                           -- return;
                        ELSE
                            classif_bilancio=dati_classif.classificazione_bil;                    
                            prec_classif_bilancio=classif_bilancio;
                        END IF;
                      ELSE
                      	classif_bilancio='';                    
						prec_classif_bilancio='';
                      END IF;
                       -- else /* evento_code = 'A' */
                                         
                      --  END IF;
                    END IF;
                    --raise notice 'NON Esiste già %',classif_bilancio;
                  end if; 
                END;        
            elsif  elenco_prime_note.evento_tipo_code='OP' OR
            		elenco_prime_note.evento_tipo_code='OI' THEN /* Ordinativo */
                BEGIN
                    /* se il record precedente aveva gli stessi dati, non eseguo di nuovo la query */                
                  if prec_num_movimento_key=elenco_prime_note.key_movimento AND 
                      prec_num_prima_nota=elenco_prime_note.num_prima_nota THEN
                      num_movimento=prec_num_movimento;
                      num_capitolo=prec_num_capitolo;
                      num_articolo=prec_num_articolo;
                      ueb=prec_ueb;
                      descr_movimento=prec_descr_movimento;
                      cod_beneficiario=prec_cod_beneficiario;
                      ragione_sociale=prec_ragione_sociale;
                      imp_movimento=prec_imp_movimento;
                      classif_bilancio=prec_classif_bilancio;
                      
                     -- raise notice 'Esiste già %',classif_bilancio;
                  ELSE                                       		                      
                        /* record nuovo: estraggo i dati del capitolo */                
                    SELECT ordinativo.ord_numero,
                    	ordinativo.ord_desc,
                        bil_elem.elem_code cod_capitolo, 
                        bil_elem.elem_code2 num_articolo,bil_elem.elem_id,
                        bil_elem.elem_code3 ueb, 
                        ts_det_ordinativo.ord_ts_det_importo imp_movimento ,
                        t_soggetto.soggetto_desc,
                        t_soggetto.soggetto_code
                    INTO dati_movimento                                     
                    FROM    	
                        siac_r_ordinativo_bil_elem  r_ord_bil_elem,
                        siac_t_bil_elem		bil_elem,
                        siac_r_ordinativo_soggetto  r_ord_soggetto,
                        siac_t_soggetto  			t_soggetto,
                        siac_t_ordinativo			ordinativo ,                        
                        siac_t_ordinativo_ts		ts_ordinativo, 
                        siac_t_ordinativo_ts_det		ts_det_ordinativo,
                        siac_d_ordinativo_ts_det_tipo  d_ts_det_ord_tipo                   
                        WHERE r_ord_bil_elem.ord_id=ordinativo.ord_id
                          and bil_elem.elem_id=r_ord_bil_elem.elem_id
                          and ordinativo.ord_id=elenco_prime_note.key_movimento    
                          and  ordinativo.ente_proprietario_id=p_ente_prop_id                       
                          and ts_ordinativo.ord_id=ordinativo.ord_id   
                          and ts_det_ordinativo.ord_ts_id  =ts_ordinativo.ord_ts_id   
                          and d_ts_det_ord_tipo.ord_ts_det_tipo_id=ts_det_ordinativo.ord_ts_det_tipo_id
                          and r_ord_soggetto.ord_id=ordinativo.ord_id
                          and t_soggetto.soggetto_id=r_ord_soggetto.soggetto_id
                          and   d_ts_det_ord_tipo.ord_ts_det_tipo_code='A'
                          and bil_elem.data_cancellazione is NULL
                          and ordinativo.data_cancellazione is NULL
                          and ts_ordinativo.data_cancellazione is NULL
                          and ts_det_ordinativo.data_cancellazione is NULL
                          and d_ts_det_ord_tipo.data_cancellazione is NULL
                          and r_ord_soggetto.data_cancellazione is NULL
                          and t_soggetto.data_cancellazione is NULL
                          and r_ord_bil_elem.data_cancellazione is NULL;               
                          
                    IF NOT FOUND THEN
                    /* 25/02/2016: se non esiste l'ordinativo non interrompo la procedura */
                        --RAISE EXCEPTION 'Non esiste l''ordinativo %', elenco_prime_note.key_movimento;
                       -- return;
                        descr_movimento='Non esiste l''ordinativo';
                    ELSE

                        num_movimento=concat('ORD/',dati_movimento.ord_numero);
                        num_capitolo=dati_movimento.cod_capitolo;
                        num_articolo=dati_movimento.num_articolo;
                        ueb=dati_movimento.ueb;
                        descr_movimento=dati_movimento.ord_desc;
                        cod_beneficiario=dati_movimento.soggetto_code;
                        ragione_sociale=dati_movimento.soggetto_desc;   
                        imp_movimento=dati_movimento.imp_movimento;

                                            
                            /* salvo i dati correnti per il prossimo record delle prime note */
                        prec_num_movimento_key=elenco_prime_note.key_movimento;
                        prec_num_prima_nota=elenco_prime_note.num_prima_nota;
                        
                        prec_num_movimento= num_movimento;
                        prec_num_capitolo=num_capitolo;
                        prec_num_articolo=num_articolo;
                        prec_ueb=ueb;
                        prec_descr_movimento=descr_movimento;
                        prec_cod_beneficiario=cod_beneficiario;
                        prec_ragione_sociale=ragione_sociale;
                        prec_imp_movimento=imp_movimento;
                        
						/* ordinativo di pagamento */
                    if elenco_prime_note.evento_tipo_code='OP' THEN 
                        idProgramma=0;
                        idMacroAggreg=0;
                            /* cerco la classificazione del capitolo.
                                mi servono solo MACROAGGREGATO e  PROGRAMMA */
                        for elenco_tipo_classif in
                            select class_tipo.classif_tipo_code, classif.classif_id
                            from siac_t_class classif, siac_d_class_tipo class_tipo, 
                                siac_r_bil_elem_class r_bil_class
                            where classif.classif_tipo_id=class_tipo.classif_tipo_id
                            and classif.classif_id=r_bil_class.classif_id
                            and r_bil_class.elem_id=dati_movimento.elem_id
                            and  classif.ente_proprietario_id=p_ente_prop_id 
                            and class_tipo.classif_tipo_code IN('MACROAGGREGATO','PROGRAMMA')
                            and classif.data_cancellazione is NULL
                            and class_tipo.data_cancellazione is NULL
                            and r_bil_class.data_cancellazione is NULL
                        loop
                            --raise notice 'Estraggo %',dati_movimento.elem_id;
                            if elenco_tipo_classif.classif_tipo_code='MACROAGGREGATO' THEN
                                idMacroAggreg = elenco_tipo_classif.classif_id;
                            elsif elenco_tipo_classif.classif_tipo_code='PROGRAMMA' THEN
                                idProgramma = elenco_tipo_classif.classif_id;
                            end if;                                                          
                          
                        end loop;
                         
                        classif_bilancio='';
                            /* cerco la classificazione del capitolo sulla tabella temporanea */
                        IF idMacroAggreg IS NOT NULL AND idProgramma IS NOT NULL THEN
                          SELECT missione_code||programma_code||'-'||titusc_code||macroag_code  classificazione_bil
                          INTO dati_classif
                          FROM siac_rep_mis_pro_tit_mac_riga_anni a
                          WHERE a.macroag_id = idMacroAggreg 
                          AND a.programma_id = idProgramma
                          and a.ente_proprietario_id=p_ente_prop_id
                          and a.utente=user_table;
                          IF NOT FOUND THEN
                              RAISE notice 'Non esiste la classificazione del capitolo di spesa 3. Elem_id = %, MacroAggr %, Programma %', dati_movimento.elem_id, idMacroAggreg, idProgramma;	
                              --return;
                          ELSE
                              classif_bilancio=dati_classif.classificazione_bil;                    
                              prec_classif_bilancio=classif_bilancio;
                          END IF;
						ELSE
                        	classif_bilancio='';                    
							prec_classif_bilancio='';
                        END IF;
                    ELSE
                    	idCategoria=0;
                          /* cerco la classificazione del capitolo.
                              mi serve solo la CATEGORIA??? */
                      for elenco_tipo_classif in
                          select class_tipo.classif_tipo_code, classif.classif_id
                          from siac_t_class classif, siac_d_class_tipo class_tipo, 
                              siac_r_bil_elem_class r_bil_class
                          where classif.classif_tipo_id=class_tipo.classif_tipo_id
                          and classif.classif_id=r_bil_class.classif_id
                          and r_bil_class.elem_id=dati_movimento.elem_id
                          and classif.ente_proprietario_id=p_ente_prop_id
                          and class_tipo.classif_tipo_code IN('CATEGORIA')
                          and classif.data_cancellazione is NULL
                          and class_tipo.data_cancellazione is NULL
                          and r_bil_class.data_cancellazione is NULL
                      loop
                          --raise notice 'Estraggo %',dati_movimento.elem_id;
                          if elenco_tipo_classif.classif_tipo_code='CATEGORIA' THEN
                              idCategoria = elenco_tipo_classif.classif_id;                          
                          end if;                                                          
                          
                      end loop;
                         
                      classif_bilancio='';
                      if idCategoria is not null then
                              /* cerco la classificazione del capitolo sulla tabella temporanea */
                          SELECT titolo_code||tipologia_code||'-'||categoria_code  classificazione_bil
                          INTO dati_classif
                          FROM siac_rep_tit_tip_cat_riga_anni a
                          WHERE a.categoria_id = idCategoria
                          and a.ente_proprietario_id=p_ente_prop_id
                          and a.utente=user_table;
                          IF NOT FOUND THEN
                               RAISE notice 'Non esiste la classificazione del capitolo di entrata. Elem_id = %', dati_movimento.elem_id;
                             -- return;
                          ELSE
                              classif_bilancio=dati_classif.classificazione_bil;                    
                              prec_classif_bilancio=classif_bilancio;
                          END IF;        
                      else
                      	classif_bilancio='';                    
                        prec_classif_bilancio='';
                      end if;            
                    END IF;
                    END IF;
                    --raise notice 'NON Esiste già %',classif_bilancio;
                  end if; 
                END;         
            elsif  elenco_prime_note.evento_tipo_code='DE' OR
            		elenco_prime_note.evento_tipo_code='DS' THEN /* Documento */                
                    /* se il record precedente aveva gli stessi dati, non eseguo di nuovo la query */                
                  if prec_num_movimento_key=elenco_prime_note.key_movimento AND 
                      prec_num_prima_nota=elenco_prime_note.num_prima_nota THEN
                      num_movimento=prec_num_movimento;
                      num_capitolo=prec_num_capitolo;
                      num_articolo=prec_num_articolo;
                      ueb=prec_ueb;
                      descr_movimento=prec_descr_movimento;
                      cod_beneficiario=prec_cod_beneficiario;
                      ragione_sociale=prec_ragione_sociale;
                      imp_movimento=prec_imp_movimento;
                      classif_bilancio=prec_classif_bilancio;
                      
                     -- raise notice 'Esiste già %',classif_bilancio;
                  ELSE                                       		                      
                        /* record nuovo: estraggo i dati del capitolo */                
                           
           			 SELECT t_doc.doc_numero, t_subdoc.subdoc_numero,  t_doc.doc_desc,
                      movgest.movgest_numero, movgest.movgest_desc,movgest.movgest_anno,
                        bil_elem.elem_code cod_capitolo, bil_elem.elem_code2 num_articolo,bil_elem.elem_id,
                        bil_elem.elem_code3 ueb, soggetto.soggetto_desc, soggetto.soggetto_code,
                       t_doc.doc_importo imp_movimento, d_doc_tipo.doc_tipo_code 
                  	INTO dati_movimento           
                    FROM siac_t_movgest		movgest,                                            
                        siac_r_subdoc_movgest_ts  r_subdoc_movgest_ts,       	
                        siac_r_movgest_bil_elem  r_movgest_bil_elem,
                        siac_t_bil_elem		bil_elem,
                        siac_t_movgest_ts	ts_movgest,
                        siac_d_doc_tipo    d_doc_tipo,
                        siac_t_doc			t_doc
                        	LEFT JOIN siac_r_doc_sog r_doc_sog
                            	ON (r_doc_sog.doc_id=t_doc.doc_id
                                	AND r_doc_sog.data_cancellazione IS NULL)
                            LEFT JOIN siac_t_soggetto		soggetto
                        		ON (soggetto.soggetto_id=r_doc_sog.soggetto_id
                                	AND soggetto.data_cancellazione IS NULL), 
                        siac_t_subdoc		t_subdoc                      
                        WHERE r_movgest_bil_elem.movgest_id=movgest.movgest_id
                          and bil_elem.elem_id=r_movgest_bil_elem.elem_id
                          and t_doc.doc_id=t_subdoc.doc_id
                          and t_subdoc.subdoc_id= elenco_prime_note.key_movimento
                          and t_doc.ente_proprietario_id=p_ente_prop_id
                          --and t_doc.doc_id=elenco_prime_note.key_movimento
                          and ts_movgest.movgest_id=movgest.movgest_id      
                          and t_subdoc.subdoc_id=r_subdoc_movgest_ts.subdoc_id
                          and r_subdoc_movgest_ts.movgest_ts_id=ts_movgest.movgest_ts_id  
                          and d_doc_tipo.doc_tipo_id=t_doc.doc_tipo_id                
                          and r_movgest_bil_elem.data_cancellazione is NULL
                          and bil_elem.data_cancellazione is NULL
                          and ts_movgest.data_cancellazione is NULL
                          and movgest.data_cancellazione is NULL                      
                          AND t_doc.data_cancellazione IS NULL
                          and t_subdoc.data_cancellazione is NULL
                          and r_subdoc_movgest_ts.data_cancellazione IS NULL
                          AND d_doc_tipo.data_cancellazione IS NULL;               
                          
                    IF NOT FOUND THEN
                    /* 25/02/2016: se non esiste la fattura non interrompo la procedura */
                        --RAISE EXCEPTION 'Non esiste la Fattura % per la Pnota %', elenco_prime_note.key_movimento, elenco_prime_note.num_prima_nota;
                       -- return;
                       descr_movimento='Non esiste la Fattura';
                    ELSE
                    		/* per le fatture, il numero di riga è
                            	il numero di quota!!! */
						num_riga=dati_movimento.subdoc_numero;
                        num_movimento=concat(dati_movimento.doc_tipo_code,'/',dati_movimento.doc_numero);
                    	/* per le fatture non stampo il capitolo, perchè potrebbero
                        	essere più di 1 */
                       -- num_capitolo=dati_movimento.cod_capitolo;
                       -- num_articolo=dati_movimento.num_articolo;
                       -- ueb=dati_movimento.ueb;
                        num_capitolo='';
                        num_articolo='';
                        ueb='';
                        descr_movimento=dati_movimento.doc_desc;
                        cod_beneficiario=dati_movimento.soggetto_code;
                        ragione_sociale=dati_movimento.soggetto_desc;   
                        imp_movimento=dati_movimento.imp_movimento;

                                            
                            /* salvo i dati correnti per il prossimo record delle prime note */
                        prec_num_movimento_key=elenco_prime_note.key_movimento;
                        prec_num_prima_nota=elenco_prime_note.num_prima_nota;
                        
                        prec_num_movimento= num_movimento;
                        prec_num_capitolo=num_capitolo;
                        prec_num_articolo=num_articolo;
                        prec_ueb=ueb;
                        prec_descr_movimento=descr_movimento;
                        prec_cod_beneficiario=cod_beneficiario;
                        prec_ragione_sociale=ragione_sociale;
                        prec_imp_movimento=imp_movimento;
                        
						
                      /* per le fatture non stampo la classificazione di bilancio */                       
                    classif_bilancio='';
                    /*if elenco_prime_note.evento_tipo_code='DS' THEN 
                  			 /* Documento di spesa */
                        idProgramma=0;
                        idMacroAggreg=0;
                            /* cerco la classificazione del capitolo.
                                mi servono solo MACROAGGREGATO e  PROGRAMMA */
                        for elenco_tipo_classif in
                            select class_tipo.classif_tipo_code, classif.classif_id
                            from siac_t_class classif, siac_d_class_tipo class_tipo, 
                                siac_r_bil_elem_class r_bil_class
                            where classif.classif_tipo_id=class_tipo.classif_tipo_id
                            and classif.classif_id=r_bil_class.classif_id
                            and r_bil_class.elem_id=dati_movimento.elem_id
                            and class_tipo.classif_tipo_code IN('MACROAGGREGATO','PROGRAMMA')
                            and classif.data_cancellazione is NULL
                            and class_tipo.data_cancellazione is NULL
                            and r_bil_class.data_cancellazione is NULL
                        loop
                            --raise notice 'Estraggo %',dati_movimento.elem_id;
                            if elenco_tipo_classif.classif_tipo_code='MACROAGGREGATO' THEN
                                idMacroAggreg = elenco_tipo_classif.classif_id;
                            elsif elenco_tipo_classif.classif_tipo_code='PROGRAMMA' THEN
                                idProgramma = elenco_tipo_classif.classif_id;
                            end if;                                                          
                          
                        end loop;
                         
                        classif_bilancio='';
                      
                            /* cerco la classificazione del capitolo sulla tabella temporanea */
                        IF idMacroAggreg IS NOT NULL AND idProgramma IS NOT NULL THEN
                          SELECT missione_code||programma_code||'-'||titusc_code||macroag_code  classificazione_bil
                          INTO dati_classif
                          FROM siac_rep_mis_pro_tit_mac_riga_anni
                          WHERE macroag_id = idMacroAggreg AND programma_id = idProgramma;
                          IF NOT FOUND THEN
                              RAISE notice 'Non esiste la classificazione del capitolo di spesa 3. Elem_id = %, MacroAggr %, Programma %', dati_movimento.elem_id, idMacroAggreg, idProgramma;	
                              --return;
                          ELSE
                              classif_bilancio=dati_classif.classificazione_bil;                    
                              prec_classif_bilancio=classif_bilancio;
                          END IF;
						ELSE
                        	classif_bilancio='';                    
							prec_classif_bilancio='';
                        END IF;
                    ELSE /* documento di entrata */
                    	idCategoria=0;
                          /* cerco la classificazione del capitolo.
                              mi serve solo la CATEGORIA??? */
                      for elenco_tipo_classif in
                          select class_tipo.classif_tipo_code, classif.classif_id
                          from siac_t_class classif, siac_d_class_tipo class_tipo, 
                              siac_r_bil_elem_class r_bil_class
                          where classif.classif_tipo_id=class_tipo.classif_tipo_id
                          and classif.classif_id=r_bil_class.classif_id
                          and r_bil_class.elem_id=dati_movimento.elem_id
                          and class_tipo.classif_tipo_code IN('CATEGORIA')
                          and classif.data_cancellazione is NULL
                          and class_tipo.data_cancellazione is NULL
                          and r_bil_class.data_cancellazione is NULL
                      loop
                          --raise notice 'Estraggo %',dati_movimento.elem_id;
                          if elenco_tipo_classif.classif_tipo_code='CATEGORIA' THEN
                              idCategoria = elenco_tipo_classif.classif_id;                          
                          end if;                                                          
                          
                      end loop;
                         
                      classif_bilancio='';
                      if idCategoria is not null then
                              /* cerco la classificazione del capitolo sulla tabella temporanea */
                          SELECT titolo_code||tipologia_code||'-'||categoria_code  classificazione_bil
                          INTO dati_classif
                          FROM siac_rep_tit_tip_cat_riga_anni
                          WHERE categoria_id = idCategoria;
                          IF NOT FOUND THEN
                               RAISE notice 'Non esiste la classificazione del capitolo di entrata. Elem_id = %', dati_movimento.elem_id;
                             -- return;
                          ELSE
                              classif_bilancio=dati_classif.classificazione_bil;                    
                              prec_classif_bilancio=classif_bilancio;
                          END IF;        
                      else
                      	classif_bilancio='';                    
                        prec_classif_bilancio='';
                      end if;            
                    END IF;*/
                    END IF;
                    --raise notice 'NON Esiste già %',classif_bilancio;
                  end if;                                 
            end if;	/* fine IF su evento_tipo_code */
                    
        return next;
        
        nome_ente='';
        num_movimento='';
        cod_beneficiario='';
        ragione_sociale='';
        num_capitolo='';
        num_articolo='';
        ueb='';
        classif_bilancio='';
        imp_movimento=0;
        descr_movimento='';
        num_prima_nota=0;
        num_prima_nota_def=0;
        data_registrazione=NULL;
        data_registrazione_def=NULL;
        stato_prima_nota='';
        descr_prima_nota='';
        cod_causale='';
        num_riga=0;
        cod_conto='';
        descr_riga='';
        importo_dare=0;
        importo_avere=0;
        key_movimento=0;
        sub_impegno='';
        soggetto_code_mod='';
    	soggetto_desc_mod='';
    
        end loop;
  
    	/* cancello le strutture temporanee dei capitoli */
	delete from siac_rep_mis_pro_tit_mac_riga_anni 	where utente=user_table;
  	delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;
  
exception
	when no_data_found THEN
		raise notice 'Prime note non trovate' ;
		--return next;
	when others  THEN
		--raise notice 'errore nella lettura delle prime note ';
        RAISE EXCEPTION '% Errore : %-%.',SQLSTATE,'PRIME NOTE',substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

--SIAC-8295 - Maurizio - FINE

--SIAC-8264
SELECT * FROM fnc_dba_add_column_params ('siac_t_operazione_asincrona', 'variazione_id' , 'INTEGER');
SELECT * FROM fnc_dba_add_fk_constraint (
	'siac_t_operazione_asincrona',
	'siac_t_operazione_asincrona_siac_t_variazione',
    'variazione_id',
  	'siac_t_variazione',
    'variazione_id'
);

--SIAC-8264

--SIAC-8305 - Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR227_Allegato_7_delibera_variazione_variabili_bozza_Prev" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar
)
RETURNS TABLE (
  id_capitolo integer,
  tipologia_capitolo varchar,
  stanziato numeric,
  variazione_aumento numeric,
  variazione_diminuzione numeric,
  anno_riferimento varchar,
  display_error varchar
) AS
$body$
DECLARE

classifBilRec record;


annoCapImp varchar;
tipoAvanzo varchar;
tipoDisavanzo varchar;
tipoFpvcc varchar;
tipoFpvsc varchar;
elemTipoCodeE varchar;
elemTipoCodeS varchar;
h_count integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
fase_bilancio varchar;
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
strQuery varchar;
tipoFci varchar;

BEGIN

annoCapImp:= p_anno; 

tipoAvanzo='AAM';
tipoDisavanzo='DAM';
tipoFpvcc='FPVCC';
tipoFpvsc='FPVSC';
tipoFci='FCI';

-- 04/04/2019: il report funziona solo per la previsione
elemTipoCodeE:='CAP-EP'; -- tipo capitolo previsione
elemTipoCodeS:='CAP-UP'; -- tipo capitolo previsione

id_capitolo=0;
tipologia_capitolo='';
stanziato=0;
variazione_aumento=0;
variazione_diminuzione=0;
anno_riferimento='';
display_error:='';


--SIAC-6163: 16/05/2018.
-- Introdotti il paramentro p_ele_variazioni  con l'elenco delle 
-- variazioni.
-- Introdotti i controlli sui parametri.
-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 intApp = strApp::numeric;
END IF;

contaParametriParz:=0;
contaParametri:=0;

if p_numero_delibera IS NOT NULL THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_anno_delibera IS NOT NULL AND p_anno_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_tipo_delibera IS NOT NULL AND p_tipo_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;

if contaParametriParz = 1 OR contaParametriParz = 2 then
	display_error:= 'ERRORE NEI PARAMETRI: Specificare tutti i dati relativi al parametro ''Provvedimento di variazione''';
    return next;
    return;
elsif contaParametriParz = 3 THEN -- parametro corretto
	contaParametri := contaParametri + 1;
end if;

contaParametriParz:=0;

if (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
	contaParametri := contaParametri + 1;
end if;


if contaParametri = 0 THEN
	display_error:= 'ERRORE NEI PARAMETRI: Specificare un parametro tra ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
elsif contaParametri = 2 THEN    
	display_error:= 'ERRORE NEI PARAMETRI: Specificare uno solo tra i parametri ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
end if;


select fnc_siac_random_user()
into	user_table;

 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep''.';  

insert into siac_rep_cap_eg
select null,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente
 from 	siac_t_bil_elem e,
        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code 	in (elemTipoCodeE,elemTipoCodeS)
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
-- INC000001570761 and	stato_capitolo.elem_stato_code		=	'VA'	
and	stato_capitolo.elem_stato_code		in ('VA', 'PR')
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
--28/06/2021 SIAC-8139
--Aggiunto tipoFci
and	cat_del_capitolo.elem_cat_code	in (tipoAvanzo,tipoDisavanzo,
	tipoFpvcc,tipoFpvsc,tipoFci)
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null;


 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep_imp''.';  

insert into siac_rep_cap_eg_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            cat_del_capitolo.elem_cat_code			tipo_imp,
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
        and	anno_eserc.anno						= 	p_anno 												
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		in (elemTipoCodeE,elemTipoCodeS)
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        --and	capitolo_imp_periodo.anno in (annoCapImp)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		-- INC000001570761 and	stato_capitolo.elem_stato_code		=	'VA'	
        and	stato_capitolo.elem_stato_code		in ('VA', 'PR')
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
            --28/06/2021 SIAC-8139
            --Aggiunto tipoFci        
  --SIAC-8305 04/08/2021.
  -- Per i capitoli di tipo FCI deve essere preso l'importo di cassa e non
  -- quello stanziato.            
		--and	cat_del_capitolo.elem_cat_code		in (tipoAvanzo,tipoDisavanzo,tipoFpvcc,tipoFpvsc,tipoFci)	
        and	((cat_del_capitolo.elem_cat_code in (tipoAvanzo,tipoDisavanzo,tipoFpvcc,
        			tipoFpvsc)  	 
               and	capitolo_imp_tipo.elem_det_tipo_code	in('STA')) OR
             (cat_del_capitolo.elem_cat_code in (tipoFci) 
              and capitolo_imp_tipo.elem_det_tipo_code	in('SCA')))                	
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
    group by capitolo_importi.elem_id,cat_del_capitolo.elem_cat_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente;
   
     RTN_MESSAGGIO:='preparazione tabella importi variazioni ''.';  

            
--SIAC-6163: 16/05/2018.
-- la query cambia a seconda del tipo parametro: atto/numeri di variazioni.
if p_numero_delibera IS NOT NULL THEN
  insert into siac_rep_var_entrate
	(elem_id, importo, utente, ente_proprietario, periodo_anno)
  select	dettaglio_variazione.elem_id,
          sum(dettaglio_variazione.elem_det_importo), -- 30.08.2017 siac-5203 Sofia - aggiunto sum
          --------cat_del_capitolo.elem_cat_code,     -- 30.08.2017 siac-5203 Sofia - commentato
          user_table utente,
          atto.ente_proprietario_id,
          anno_importo.anno	      	
  from 	siac_t_atto_amm 			atto,
          siac_d_atto_amm_tipo		tipo_atto,
          siac_r_atto_amm_stato 		r_atto_stato,
          siac_d_atto_amm_stato 		stato_atto,
          siac_r_variazione_stato		r_variazione_stato,
          siac_t_variazione 			testata_variazione,
          siac_d_variazione_tipo		tipologia_variazione,
          siac_d_variazione_stato 	tipologia_stato_var,
          siac_t_bil_elem_det_var 	dettaglio_variazione,
          siac_t_bil_elem				capitolo,
          siac_d_bil_elem_tipo 		tipo_capitolo,
          siac_d_bil_elem_det_tipo	tipo_elemento,
          siac_d_bil_elem_categoria 	cat_del_capitolo, 
          siac_r_bil_elem_categoria 	r_cat_capitolo,
          siac_t_periodo 				anno_eserc,
          siac_t_periodo              anno_importo ,
          siac_t_bil                  bilancio  
  where 	atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
  and		r_atto_stato.attoamm_id								=	atto.attoamm_id
  and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
  and		( r_variazione_stato.attoamm_id						=	atto.attoamm_id or
            r_variazione_stato.attoamm_id_varbil				=	atto.attoamm_id)
  and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
  and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
  and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id			
  and     anno_eserc.periodo_id                               = bilancio.periodo_id
  and     testata_variazione.bil_id                           = bilancio.bil_id 
  and     capitolo.bil_id                                     = bilancio.bil_id 
  and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
  and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
  and		dettaglio_variazione.elem_id						=	capitolo.elem_id
  and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
  and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
  and		capitolo.elem_id									=	r_cat_capitolo.elem_id
  and		r_cat_capitolo.elem_cat_id							=	cat_del_capitolo.elem_cat_id
  -- 15/06/2016: cambiati i tipi di variazione. Aggiunto 'AS'.
  --and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF')
  -- 19/07/2016: tolto il test sul tipo di variazione: accettate tutte.
  --and		tipologia_variazione.variazione_tipo_code			in ('ST','VA', 'VR', 'PF', 'AS')
  and		atto.ente_proprietario_id 							= 	p_ente_prop_id
  and		anno_eserc.anno										= 	p_anno 		
  and		atto.attoamm_numero 								= 	p_numero_delibera
  and		atto.attoamm_anno									=	p_anno_delibera
  and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera
  and		tipologia_stato_var.variazione_stato_tipo_code		in	('B','G', 'C', 'P')										
  and     anno_importo.anno                                   =   p_anno_competenza					
  and		tipo_capitolo.elem_tipo_code						in (elemTipoCodeE,elemTipoCodeS)
  --SIAC-8305 04/08/2021.
  -- Per i capitoli di tipo FCI deve essere preso l'importo di cassa e non
  -- quello stanziato.
  --and		tipo_elemento.elem_det_tipo_code					= 'STA'
    --28/06/2021 SIAC-8139
    --Aggiunto tipoFci  
 -- and		cat_del_capitolo.elem_cat_code	in (tipoAvanzo,tipoDisavanzo,
  --		tipoFpvcc,tipoFpvsc,tipoFci)	
  and ((cat_del_capitolo.elem_cat_code	in (tipoAvanzo,tipoDisavanzo,
  											tipoFpvcc,tipoFpvsc)
       and	tipo_elemento.elem_det_tipo_code					= 'STA') OR
        (cat_del_capitolo.elem_cat_code	in (tipoFci)
         and tipo_elemento.elem_det_tipo_code					= 'SCA'))
  and		atto.data_cancellazione						is null
  and		tipo_atto.data_cancellazione				is null
  and		r_atto_stato.data_cancellazione				is null
  and		stato_atto.data_cancellazione				is null
  and		r_variazione_stato.data_cancellazione		is null
  and		testata_variazione.data_cancellazione		is null
  and		tipologia_variazione.data_cancellazione		is null
  and		tipologia_stato_var.data_cancellazione		is null
  and 	dettaglio_variazione.data_cancellazione		is null
  and 	capitolo.data_cancellazione					is null
  and		tipo_capitolo.data_cancellazione			is null
  and		tipo_elemento.data_cancellazione			is null
  and		cat_del_capitolo.data_cancellazione			is null 
  and     r_cat_capitolo.data_cancellazione			is null
  group by 	dettaglio_variazione.elem_id, -- -- 30.08.2017 siac-5203 Sofia aggiunto group by per sum
              utente,
              atto.ente_proprietario_id,
              anno_importo.anno;
else
	strQuery:='
    	insert into siac_rep_var_entrate
	(elem_id, importo, utente, ente_proprietario, periodo_anno)
          select	dettaglio_variazione.elem_id,
          sum(dettaglio_variazione.elem_det_importo),
          '''||user_table||''' utente,
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
          siac_d_bil_elem_categoria 	cat_del_capitolo, 
          siac_r_bil_elem_categoria 	r_cat_capitolo,
          siac_t_periodo 				anno_eserc,
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
  and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
  and		capitolo.elem_id									=	r_cat_capitolo.elem_id
  and		r_cat_capitolo.elem_cat_id							=	cat_del_capitolo.elem_cat_id
  and		testata_variazione.ente_proprietario_id 			= 	'||p_ente_prop_id||'
  and 	testata_variazione.variazione_num 						in   ('||p_ele_variazioni||')
  and		anno_eserc.anno										= 	'''||p_anno||''' 		
  and		tipologia_stato_var.variazione_stato_tipo_code		in	(''B'',''G'', ''C'', ''P'')										
  and     anno_importo.anno                                   =   '''||p_anno_competenza||'''					
  and		tipo_capitolo.elem_tipo_code						in ('''||elemTipoCodeE||''','''||elemTipoCodeS||''')
  --and		tipo_elemento.elem_det_tipo_code					= ''STA''
    --28/06/2021 SIAC-8139
    --Aggiunto tipoFci    
  --SIAC-8305 04/08/2021.
  -- Per i capitoli di tipo FCI deve essere preso l''importo di cassa e non
  -- quello stanziato.    
  --and		cat_del_capitolo.elem_cat_code						in ('''||tipoAvanzo||''','''||tipoDisavanzo||''','''||tipoFpvcc||''','''||tipoFpvsc||''','''||tipoFci||''')	
  and	((cat_del_capitolo.elem_cat_code in ('''||tipoAvanzo||''','''||tipoDisavanzo||''','''||tipoFpvcc||''','''||tipoFpvsc||''')
          and tipo_elemento.elem_det_tipo_code					= ''STA'') OR
         (cat_del_capitolo.elem_cat_code in ('''||tipoFci||''') 
          and tipo_elemento.elem_det_tipo_code					= ''SCA''))
  and		r_variazione_stato.data_cancellazione		is null
  and		testata_variazione.data_cancellazione		is null
  and		tipologia_variazione.data_cancellazione		is null
  and		tipologia_stato_var.data_cancellazione		is null
  and 	dettaglio_variazione.data_cancellazione		is null
  and 	capitolo.data_cancellazione					is null
  and		tipo_capitolo.data_cancellazione			is null
  and		tipo_elemento.data_cancellazione			is null
  and		cat_del_capitolo.data_cancellazione			is null 
  and     r_cat_capitolo.data_cancellazione			is null
  group by 	dettaglio_variazione.elem_id, 
              utente,
              testata_variazione.ente_proprietario_id,
              anno_importo.anno'; 

raise notice 'strQuery = %', strQuery;

execute strQuery;                    
end if;                  	                          
    
     RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  

insert into siac_rep_var_entrate_riga
select  tb0.elem_id,       
		tb1.importo        as 		variazione_aumento_stanziato,
        tb2.importo        as 		variazione_diminuzione_stanziato,
        0,
        0,
        0,
        0,
        user_table utente,
        p_ente_prop_id,
        p_anno
from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
        --and tb1.tipologia  	= 'STA'	
        and 	tb1.importo > 0	
        and     tb1.periodo_anno=p_anno
        and     tb1.utente = tb0.utente
         ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	--and tb2.tipologia  	= 'STA'	
        AND	tb2.importo < 0	
        and tb2.periodo_anno =p_anno 
         and     tb2.utente = tb0.utente)
    where  tb0.utente = user_table 
  union 
  select  tb0.elem_id,       
		tb1.importo        as 		variazione_aumento_stanziato,
        tb2.importo        as 		variazione_diminuzione_stanziato,
        0,
        0,
        0,
        0,
        user_table utente,
        p_ente_prop_id,
        (p_anno::INTEGER + 1)::varchar
    from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
        --and tb1.tipologia  	= 'STA'	
        and 	tb1.importo > 0	
        and     tb1.periodo_anno=(p_anno::INTEGER + 1)::varchar
        and     tb1.utente = tb0.utente
         ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	--and tb2.tipologia  	= 'STA'	
        AND	tb2.importo < 0	
        and tb2.periodo_anno =(p_anno::INTEGER + 1)::varchar 
         and     tb2.utente = tb0.utente)
    where  tb0.utente = user_table 
  union 
  select  tb0.elem_id,       
		tb1.importo        as 		variazione_aumento_stanziato,
        tb2.importo        as 		variazione_diminuzione_stanziato,
        0,
        0,
        0,
        0,
        user_table utente,
        p_ente_prop_id,
        (p_anno::INTEGER + 2)::varchar
    from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
        --and tb1.tipologia  	= 'STA'	
        and 	tb1.importo > 0	
        and     tb1.periodo_anno=(p_anno::INTEGER + 2)::varchar
        and     tb1.utente = tb0.utente
         ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	--and tb2.tipologia  	= 'STA'	
        AND	tb2.importo < 0	
        and tb2.periodo_anno =(p_anno::INTEGER + 2)::varchar 
         and     tb2.utente = tb0.utente)
    where  tb0.utente = user_table 
     ;

     RTN_MESSAGGIO:='preparazione file output ''.';          

for classifBilRec in
select 	tb1.elem_id   		 											id_capitolo,
       	tb1.tipo_imp    												tipologia_capitolo,
       	tb1.importo     												stanziato,
       	COALESCE (tb2.variazione_aumento_stanziato,0)     				variazione_aumento,
       	COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)			variazione_diminuzione,
        tb1.periodo_anno                                                anno_riferimento          
from  	siac_rep_cap_eg_imp tb1  
            left	join    siac_rep_var_entrate_riga tb2  
            on (tb2.elem_id	=	tb1.elem_id
                    and tb1.periodo_anno=tb2.periodo_anno
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table) 
    where tb1.utente = user_table

loop

id_capitolo := classifBilRec.id_capitolo;
tipologia_capitolo := classifBilRec.tipologia_capitolo;
stanziato := classifBilRec.stanziato;

variazione_aumento := classifBilRec.variazione_aumento;
variazione_diminuzione := classifBilRec.variazione_diminuzione;
anno_riferimento := classifBilRec.anno_riferimento;

return next;

end loop;

return next;

delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;
delete from siac_rep_cap_eg where utente=user_table;
delete from siac_rep_cap_eg_imp where utente=user_table;
delete from siac_rep_cap_eg_imp_riga where utente=user_table;
delete from	siac_rep_var_entrate	where utente=user_table;
delete from siac_rep_var_entrate_riga where utente=user_table; 


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
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

--SIAC-8305 - Maurizio - FINE


--SIAC-8322 - Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR256_Allegato_8_delibera_variazione_definitive_Prev_variab" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar
)
RETURNS TABLE (
  id_capitolo integer,
  tipologia_capitolo varchar,
  stanziato numeric,
  variazione_aumento numeric,
  variazione_diminuzione numeric,
  anno_riferimento varchar,
  display_error varchar
) AS
$body$
DECLARE

/* 02/07/2021 SIAC-8152.
	Funzione copia della BILR227_Allegato_7_delibera_variazione_variabili_bozza_Prev
    per il nuovo report BILR257 che differisce dal BILR227 per il fatto 
    che le variazioni estratte sono in stato DEFINITIVO.
*/

classifBilRec record;


annoCapImp varchar;
tipoAvanzo varchar;
tipoDisavanzo varchar;
tipoFpvcc varchar;
tipoFpvsc varchar;
elemTipoCodeE varchar;
elemTipoCodeS varchar;
h_count integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
fase_bilancio varchar;
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
strQuery varchar;
tipoFci varchar;

BEGIN

annoCapImp:= p_anno; 

tipoAvanzo='AAM';
tipoDisavanzo='DAM';
tipoFpvcc='FPVCC';
tipoFpvsc='FPVSC';
tipoFci='FCI';

-- 04/04/2019: il report funziona solo per la previsione
elemTipoCodeE:='CAP-EP'; -- tipo capitolo previsione
elemTipoCodeS:='CAP-UP'; -- tipo capitolo previsione

id_capitolo=0;
tipologia_capitolo='';
stanziato=0;
variazione_aumento=0;
variazione_diminuzione=0;
anno_riferimento='';
display_error:='';

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 intApp = strApp::numeric;
END IF;

contaParametriParz:=0;
contaParametri:=0;

if p_numero_delibera IS NOT NULL THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_anno_delibera IS NOT NULL AND p_anno_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_tipo_delibera IS NOT NULL AND p_tipo_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;

if contaParametriParz = 1 OR contaParametriParz = 2 then
	display_error:= 'ERRORE NEI PARAMETRI: Specificare tutti i dati relativi al parametro ''Provvedimento di variazione''';
    return next;
    return;
elsif contaParametriParz = 3 THEN -- parametro corretto
	contaParametri := contaParametri + 1;
end if;

contaParametriParz:=0;

if (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
	contaParametri := contaParametri + 1;
end if;


if contaParametri = 0 THEN
	display_error:= 'ERRORE NEI PARAMETRI: Specificare un parametro tra ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
elsif contaParametri = 2 THEN    
	display_error:= 'ERRORE NEI PARAMETRI: Specificare uno solo tra i parametri ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
end if;


select fnc_siac_random_user()
into	user_table;

 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep''.';  

insert into siac_rep_cap_eg
select null,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente
 from 	siac_t_bil_elem e,
        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code 	in (elemTipoCodeE,elemTipoCodeS)
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
-- INC000001570761 and	stato_capitolo.elem_stato_code		=	'VA'	
and	stato_capitolo.elem_stato_code		in ('VA', 'PR')
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
--28/06/2021 SIAC-8139
--Aggiunto tipoFci
and	cat_del_capitolo.elem_cat_code	in (tipoAvanzo,tipoDisavanzo,
	tipoFpvcc,tipoFpvsc,tipoFci)
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null;


 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep_imp''.';  

insert into siac_rep_cap_eg_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            cat_del_capitolo.elem_cat_code			tipo_imp,
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
        and	anno_eserc.anno						= 	p_anno 												
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		in (elemTipoCodeE,elemTipoCodeS)
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id
        --and	capitolo_imp_tipo.elem_det_tipo_code	=	'STA' 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        --and	capitolo_imp_periodo.anno in (annoCapImp)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		-- INC000001570761 and	stato_capitolo.elem_stato_code		=	'VA'	
        and	stato_capitolo.elem_stato_code		in ('VA', 'PR')
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
            --28/06/2021 SIAC-8139
            --Aggiunto tipoFci      
  --SIAC-8322 30/08/2021.
  -- Per i capitoli di tipo FCI deve essere preso l'importo di cassa e non
  -- quello stanziato.            
		--and	cat_del_capitolo.elem_cat_code		in (tipoAvanzo,tipoDisavanzo,tipoFpvcc,tipoFpvsc,tipoFci)	
        and	((cat_del_capitolo.elem_cat_code in (tipoAvanzo,tipoDisavanzo,tipoFpvcc,
        			tipoFpvsc)  	 
               and	capitolo_imp_tipo.elem_det_tipo_code	in('STA')) OR
             (cat_del_capitolo.elem_cat_code in (tipoFci) 
              and capitolo_imp_tipo.elem_det_tipo_code	in('SCA')))                    		
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
    group by capitolo_importi.elem_id,cat_del_capitolo.elem_cat_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente;
   
     RTN_MESSAGGIO:='preparazione tabella importi variazioni ''.';  

            
--SIAC-6163: 16/05/2018.
-- la query cambia a seconda del tipo parametro: atto/numeri di variazioni.
if p_numero_delibera IS NOT NULL THEN
  insert into siac_rep_var_entrate
	(elem_id, importo, utente, ente_proprietario, periodo_anno)
  select	dettaglio_variazione.elem_id,
          sum(dettaglio_variazione.elem_det_importo), -- 30.08.2017 siac-5203 Sofia - aggiunto sum
          --------cat_del_capitolo.elem_cat_code,     -- 30.08.2017 siac-5203 Sofia - commentato
          user_table utente,
          atto.ente_proprietario_id,
          anno_importo.anno	      	
  from 	siac_t_atto_amm 			atto,
          siac_d_atto_amm_tipo		tipo_atto,
          siac_r_atto_amm_stato 		r_atto_stato,
          siac_d_atto_amm_stato 		stato_atto,
          siac_r_variazione_stato		r_variazione_stato,
          siac_t_variazione 			testata_variazione,
          siac_d_variazione_tipo		tipologia_variazione,
          siac_d_variazione_stato 	tipologia_stato_var,
          siac_t_bil_elem_det_var 	dettaglio_variazione,
          siac_t_bil_elem				capitolo,
          siac_d_bil_elem_tipo 		tipo_capitolo,
          siac_d_bil_elem_det_tipo	tipo_elemento,
          siac_d_bil_elem_categoria 	cat_del_capitolo, 
          siac_r_bil_elem_categoria 	r_cat_capitolo,
          siac_t_periodo 				anno_eserc,
          siac_t_periodo              anno_importo ,
          siac_t_bil                  bilancio  
  where 	atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
  and		r_atto_stato.attoamm_id								=	atto.attoamm_id
  and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
  and		( r_variazione_stato.attoamm_id						=	atto.attoamm_id or
            r_variazione_stato.attoamm_id_varbil				=	atto.attoamm_id)
  and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
  and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
  and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id			
  and     anno_eserc.periodo_id                               = bilancio.periodo_id
  and     testata_variazione.bil_id                           = bilancio.bil_id 
  and     capitolo.bil_id                                     = bilancio.bil_id 
  and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
  and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
  and		dettaglio_variazione.elem_id						=	capitolo.elem_id
  and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
  and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
  and		capitolo.elem_id									=	r_cat_capitolo.elem_id
  and		r_cat_capitolo.elem_cat_id							=	cat_del_capitolo.elem_cat_id
  and		atto.ente_proprietario_id 							= 	p_ente_prop_id
  and		anno_eserc.anno										= 	p_anno 		
  and		atto.attoamm_numero 								= 	p_numero_delibera
  and		atto.attoamm_anno									=	p_anno_delibera
  and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera
  and		tipologia_stato_var.variazione_stato_tipo_code		in	('D')										
  and     anno_importo.anno                                   =   p_anno_competenza					
  and		tipo_capitolo.elem_tipo_code						in (elemTipoCodeE,elemTipoCodeS)
--SIAC-8322 30/08/2021.
-- Per i capitoli di tipo FCI deve essere preso l'importo di cassa e non
  -- quello stanziato. 
 --and		tipo_elemento.elem_det_tipo_code					= 'STA'
    --28/06/2021 SIAC-8139
    --Aggiunto tipoFci  
 -- and		cat_del_capitolo.elem_cat_code	in (tipoAvanzo,tipoDisavanzo,
 -- 		tipoFpvcc,tipoFpvsc,tipoFci)	
 and ((cat_del_capitolo.elem_cat_code	in (tipoAvanzo,tipoDisavanzo,
  											tipoFpvcc,tipoFpvsc)
       and	tipo_elemento.elem_det_tipo_code					= 'STA') OR
        (cat_del_capitolo.elem_cat_code	in (tipoFci)
         and tipo_elemento.elem_det_tipo_code					= 'SCA')) 
  and		atto.data_cancellazione						is null
  and		tipo_atto.data_cancellazione				is null
  and		r_atto_stato.data_cancellazione				is null
  and		stato_atto.data_cancellazione				is null
  and		r_variazione_stato.data_cancellazione		is null
  and		testata_variazione.data_cancellazione		is null
  and		tipologia_variazione.data_cancellazione		is null
  and		tipologia_stato_var.data_cancellazione		is null
  and 	dettaglio_variazione.data_cancellazione		is null
  and 	capitolo.data_cancellazione					is null
  and		tipo_capitolo.data_cancellazione			is null
  and		tipo_elemento.data_cancellazione			is null
  and		cat_del_capitolo.data_cancellazione			is null 
  and     r_cat_capitolo.data_cancellazione			is null
  group by 	dettaglio_variazione.elem_id, -- -- 30.08.2017 siac-5203 Sofia aggiunto group by per sum
              utente,
              atto.ente_proprietario_id,
              anno_importo.anno;
else
	strQuery:='
    	insert into siac_rep_var_entrate
	(elem_id, importo, utente, ente_proprietario, periodo_anno)
          select	dettaglio_variazione.elem_id,
          sum(dettaglio_variazione.elem_det_importo),
          '''||user_table||''' utente,
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
          siac_d_bil_elem_categoria 	cat_del_capitolo, 
          siac_r_bil_elem_categoria 	r_cat_capitolo,
          siac_t_periodo 				anno_eserc,
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
  and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
  and		capitolo.elem_id									=	r_cat_capitolo.elem_id
  and		r_cat_capitolo.elem_cat_id							=	cat_del_capitolo.elem_cat_id
  and		testata_variazione.ente_proprietario_id 			= 	'||p_ente_prop_id||'
  and 	testata_variazione.variazione_num 						in   ('||p_ele_variazioni||')
  and		anno_eserc.anno										= 	'''||p_anno||''' 		
  and		tipologia_stato_var.variazione_stato_tipo_code		in	(''D'')										
  and     anno_importo.anno                                   =   '''||p_anno_competenza||'''					
  and		tipo_capitolo.elem_tipo_code						in ('''||elemTipoCodeE||''','''||elemTipoCodeS||''')
  and		tipo_elemento.elem_det_tipo_code					= ''STA''
    --28/06/2021 SIAC-8139
    --Aggiunto tipoFci    
--SIAC-8322 30/08/2021.    
-- Per i capitoli di tipo FCI deve essere preso l''importo di cassa e non
  -- quello stanziato.    
  --and		cat_del_capitolo.elem_cat_code						in ('''||tipoAvanzo||''','''||tipoDisavanzo||''','''||tipoFpvcc||''','''||tipoFpvsc||''','''||tipoFci||''')	
and	((cat_del_capitolo.elem_cat_code in ('''||tipoAvanzo||''','''||tipoDisavanzo||''','''||tipoFpvcc||''','''||tipoFpvsc||''')
          and tipo_elemento.elem_det_tipo_code					= ''STA'') OR
         (cat_del_capitolo.elem_cat_code in ('''||tipoFci||''') 
          and tipo_elemento.elem_det_tipo_code					= ''SCA'')) 
  and		r_variazione_stato.data_cancellazione		is null
  and		testata_variazione.data_cancellazione		is null
  and		tipologia_variazione.data_cancellazione		is null
  and		tipologia_stato_var.data_cancellazione		is null
  and 	dettaglio_variazione.data_cancellazione		is null
  and 	capitolo.data_cancellazione					is null
  and		tipo_capitolo.data_cancellazione			is null
  and		tipo_elemento.data_cancellazione			is null
  and		cat_del_capitolo.data_cancellazione			is null 
  and     r_cat_capitolo.data_cancellazione			is null
  group by 	dettaglio_variazione.elem_id, 
              utente,
              testata_variazione.ente_proprietario_id,
              anno_importo.anno'; 

raise notice 'strQuery = %', strQuery;

execute strQuery;                    
end if;                  	                          
    
     RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  

insert into siac_rep_var_entrate_riga
select  tb0.elem_id,       
		tb1.importo        as 		variazione_aumento_stanziato,
        tb2.importo        as 		variazione_diminuzione_stanziato,
        0,
        0,
        0,
        0,
        user_table utente,
        p_ente_prop_id,
        p_anno
from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
        --and tb1.tipologia  	= 'STA'	
        and 	tb1.importo > 0	
        and     tb1.periodo_anno=p_anno
        and     tb1.utente = tb0.utente
         ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	--and tb2.tipologia  	= 'STA'	
        AND	tb2.importo < 0	
        and tb2.periodo_anno =p_anno 
         and     tb2.utente = tb0.utente)
    where  tb0.utente = user_table 
  union 
  select  tb0.elem_id,       
		tb1.importo        as 		variazione_aumento_stanziato,
        tb2.importo        as 		variazione_diminuzione_stanziato,
        0,
        0,
        0,
        0,
        user_table utente,
        p_ente_prop_id,
        (p_anno::INTEGER + 1)::varchar
    from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
        --and tb1.tipologia  	= 'STA'	
        and 	tb1.importo > 0	
        and     tb1.periodo_anno=(p_anno::INTEGER + 1)::varchar
        and     tb1.utente = tb0.utente
         ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	--and tb2.tipologia  	= 'STA'	
        AND	tb2.importo < 0	
        and tb2.periodo_anno =(p_anno::INTEGER + 1)::varchar 
         and     tb2.utente = tb0.utente)
    where  tb0.utente = user_table 
  union 
  select  tb0.elem_id,       
		tb1.importo        as 		variazione_aumento_stanziato,
        tb2.importo        as 		variazione_diminuzione_stanziato,
        0,
        0,
        0,
        0,
        user_table utente,
        p_ente_prop_id,
        (p_anno::INTEGER + 2)::varchar
    from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
        --and tb1.tipologia  	= 'STA'	
        and 	tb1.importo > 0	
        and     tb1.periodo_anno=(p_anno::INTEGER + 2)::varchar
        and     tb1.utente = tb0.utente
         ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	--and tb2.tipologia  	= 'STA'	
        AND	tb2.importo < 0	
        and tb2.periodo_anno =(p_anno::INTEGER + 2)::varchar 
         and     tb2.utente = tb0.utente)
    where  tb0.utente = user_table 
     ;

     RTN_MESSAGGIO:='preparazione file output ''.';          

for classifBilRec in
select 	tb1.elem_id   		 											id_capitolo,
       	tb1.tipo_imp    												tipologia_capitolo,
       	tb1.importo     												stanziato,
       	COALESCE (tb2.variazione_aumento_stanziato,0)     				variazione_aumento,
       	COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)			variazione_diminuzione,
        tb1.periodo_anno                                                anno_riferimento          
from  	siac_rep_cap_eg_imp tb1  
            left	join    siac_rep_var_entrate_riga tb2  
            on (tb2.elem_id	=	tb1.elem_id
                    and tb1.periodo_anno=tb2.periodo_anno
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table) 
    where tb1.utente = user_table

loop

id_capitolo := classifBilRec.id_capitolo;
tipologia_capitolo := classifBilRec.tipologia_capitolo;
stanziato := classifBilRec.stanziato;

variazione_aumento := classifBilRec.variazione_aumento;
variazione_diminuzione := classifBilRec.variazione_diminuzione;
anno_riferimento := classifBilRec.anno_riferimento;

return next;

end loop;

return next;

delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;
delete from siac_rep_cap_eg where utente=user_table;
delete from siac_rep_cap_eg_imp where utente=user_table;
delete from siac_rep_cap_eg_imp_riga where utente=user_table;
delete from	siac_rep_var_entrate	where utente=user_table;
delete from siac_rep_var_entrate_riga where utente=user_table; 



raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
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

--SIAC-8322 - Maurizio - FINE