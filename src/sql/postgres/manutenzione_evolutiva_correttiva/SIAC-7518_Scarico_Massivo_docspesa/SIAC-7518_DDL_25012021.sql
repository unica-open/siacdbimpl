/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿drop table if exists siac.siac_dwh_st_documento_spesa;
CREATE TABLE siac.siac_dwh_st_documento_spesa
(
  ente_proprietario_id INTEGER,
  ente_denominazione VARCHAR(500),
  anno_atto_amministrativo VARCHAR(4),
  num_atto_amministrativo VARCHAR(200),
  oggetto_atto_amministrativo VARCHAR(500),
  cod_tipo_atto_amministrativo VARCHAR(200),
  desc_tipo_atto_amministrativo VARCHAR(200),
  cod_cdr_atto_amministrativo VARCHAR(200),
  desc_cdr_atto_amministrativo VARCHAR(500),
  cod_cdc_atto_amministrativo VARCHAR(200),
  desc_cdc_atto_amministrativo VARCHAR(500),
  note_atto_amministrativo VARCHAR(500),
  cod_stato_atto_amministrativo VARCHAR(200),
  desc_stato_atto_amministrativo VARCHAR(200),
  causale_atto_allegato VARCHAR(500),
  altri_allegati_atto_allegato VARCHAR(500),
  dati_sensibili_atto_allegato VARCHAR(1),
  data_scadenza_atto_allegato TIMESTAMP WITHOUT TIME ZONE,
  note_atto_allegato VARCHAR(500),
  annotazioni_atto_allegato VARCHAR(500),
  pratica_atto_allegato VARCHAR(500),
  resp_amm_atto_allegato VARCHAR(500),
  resp_contabile_atto_allegato VARCHAR(500),
  anno_titolario_atto_allegato INTEGER,
  num_titolario_atto_allegato VARCHAR(500),
  vers_invio_firma_atto_allegato INTEGER,
  cod_stato_atto_allegato VARCHAR(200),
  desc_stato_atto_allegato VARCHAR(200),
  sogg_id_atto_allegato INTEGER,
  cod_sogg_atto_allegato VARCHAR(200),
  tipo_sogg_atto_allegato VARCHAR(500),
  stato_sogg_atto_allegato VARCHAR(500),
  rag_sociale_sogg_atto_allegato VARCHAR(500),
  p_iva_sogg_atto_allegato VARCHAR(500),
  cf_sogg_atto_allegato VARCHAR(16),
  cf_estero_sogg_atto_allegato VARCHAR(500),
  nome_sogg_atto_allegato VARCHAR(500),
  cognome_sogg_atto_allegato VARCHAR(500),
  anno_doc INTEGER,
  num_doc VARCHAR(200),
  desc_doc VARCHAR(500),
  importo_doc NUMERIC,
  beneficiario_multiplo_doc VARCHAR(1),
  data_emissione_doc TIMESTAMP WITHOUT TIME ZONE,
  data_scadenza_doc TIMESTAMP WITHOUT TIME ZONE,
  codice_bollo_doc VARCHAR(200),
  desc_codice_bollo_doc VARCHAR(500),
  collegato_cec_doc VARCHAR(200),
  cod_pcc_doc VARCHAR(200),
  desc_pcc_doc VARCHAR(500),
  cod_ufficio_doc VARCHAR(200),
  desc_ufficio_doc VARCHAR(500),
  cod_stato_doc VARCHAR(200),
  desc_stato_doc VARCHAR(500),
  anno_elenco_doc INTEGER,
  num_elenco_doc INTEGER,
  data_trasmissione_elenco_doc TIMESTAMP WITHOUT TIME ZONE,
  tot_quote_entrate_elenco_doc NUMERIC,
  tot_quote_spese_elenco_doc NUMERIC,
  tot_da_pagare_elenco_doc NUMERIC,
  tot_da_incassare_elenco_doc NUMERIC,
  cod_stato_elenco_doc VARCHAR(200),
  desc_stato_elenco_doc VARCHAR(500),
  cod_gruppo_doc VARCHAR(200),
  desc_famiglia_doc VARCHAR(500),
  cod_famiglia_doc VARCHAR(200),
  desc_gruppo_doc VARCHAR(500),
  cod_tipo_doc VARCHAR(200),
  desc_tipo_doc VARCHAR(500),
  sogg_id_doc INTEGER,
  cod_sogg_doc VARCHAR(200),
  tipo_sogg_doc VARCHAR(500),
  stato_sogg_doc VARCHAR(500),
  rag_sociale_sogg_doc VARCHAR(500),
  p_iva_sogg_doc VARCHAR(500),
  cf_sogg_doc VARCHAR(16),
  cf_estero_sogg_doc VARCHAR(500),
  nome_sogg_doc VARCHAR(500),
  cognome_sogg_doc VARCHAR(500),
  num_subdoc INTEGER,
  desc_subdoc VARCHAR(500),
  importo_subdoc NUMERIC,
  num_reg_iva_subdoc VARCHAR(500),
  data_scadenza_subdoc TIMESTAMP WITHOUT TIME ZONE,
  convalida_manuale_subdoc VARCHAR(1),
  importo_da_dedurre_subdoc NUMERIC,
  splitreverse_importo_subdoc NUMERIC,
  pagato_cec_subdoc VARCHAR(1),
  data_pagamento_cec_subdoc TIMESTAMP WITHOUT TIME ZONE,
  note_tesoriere_subdoc VARCHAR(500),
  cod_distinta_subdoc VARCHAR(200),
  desc_distinta_subdoc VARCHAR(500),
  tipo_commissione_subdoc VARCHAR(500),
  conto_tesoreria_subdoc VARCHAR(500),
  rilevante_iva VARCHAR(1),
  ordinativo_singolo VARCHAR(1),
  ordinativo_manuale VARCHAR(1),
  esproprio VARCHAR(1),
  note VARCHAR(500),
  cig VARCHAR(500),
  cup VARCHAR(500),
  causale_sospensione VARCHAR(500),
  data_sospensione VARCHAR(500),
  data_riattivazione VARCHAR(500),
  causale_ordinativo VARCHAR(500),
  num_mutuo INTEGER,
  annotazione VARCHAR(500),
  certificazione VARCHAR(1),
  data_certificazione VARCHAR(500),
  note_certificazione VARCHAR(500),
  num_certificazione VARCHAR(500),
  data_scadenza_dopo_sospensione VARCHAR(500),
  data_esecuzione_pagamento VARCHAR(500),
  avviso VARCHAR(1),
  cod_tipo_avviso VARCHAR(200),
  desc_tipo_avviso VARCHAR(500),
  sogg_id_subdoc INTEGER,
  cod_sogg_subdoc VARCHAR(200),
  tipo_sogg_subdoc VARCHAR(500),
  stato_sogg_subdoc VARCHAR(500),
  rag_sociale_sogg_subdoc VARCHAR(500),
  p_iva_sogg_subdoc VARCHAR(500),
  cf_sogg_subdoc VARCHAR(16),
  cf_estero_sogg_subdoc VARCHAR(500),
  nome_sogg_subdoc VARCHAR(500),
  cognome_sogg_subdoc VARCHAR(500),
  sede_secondaria_subdoc VARCHAR(1),
  bil_anno VARCHAR(4),
  anno_impegno INTEGER,
  num_impegno NUMERIC,
  cod_impegno VARCHAR(200),
  desc_impegno VARCHAR(500),
  cod_subimpegno VARCHAR(200),
  desc_subimpegno VARCHAR(500),
  num_liquidazione NUMERIC,
  cod_tipo_accredito VARCHAR(200),
  desc_tipo_accredito VARCHAR(200),
  mod_pag_id INTEGER,
  quietanziante VARCHAR(500),
  data_nascita_quietanziante TIMESTAMP WITHOUT TIME ZONE,
  luogo_nascita_quietanziante VARCHAR(500),
  stato_nascita_quietanziante VARCHAR(500),
  bic VARCHAR(500),
  contocorrente VARCHAR(500),
  intestazione_contocorrente VARCHAR(500),
  iban VARCHAR(500),
  note_mod_pag VARCHAR(500),
  data_scadenza_mod_pag TIMESTAMP WITHOUT TIME ZONE,
  sogg_id_mod_pag INTEGER,
  cod_sogg_mod_pag VARCHAR(200),
  tipo_sogg_mod_pag VARCHAR(500),
  stato_sogg_mod_pag VARCHAR(500),
  rag_sociale_sogg_mod_pag VARCHAR(500),
  p_iva_sogg_mod_pag VARCHAR(500),
  cf_sogg_mod_pag VARCHAR(16),
  cf_estero_sogg_mod_pag VARCHAR(500),
  nome_sogg_mod_pag VARCHAR(500),
  cognome_sogg_mod_pag VARCHAR(500),
  anno_liquidazione INTEGER,
  bil_anno_ord VARCHAR(4),
  anno_ord INTEGER,
  num_ord NUMERIC,
  num_subord VARCHAR(200),
  data_elaborazione TIMESTAMP WITHOUT TIME ZONE,
  registro_repertorio VARCHAR(200),
  anno_repertorio VARCHAR(4),
  num_repertorio VARCHAR(200),
  data_repertorio VARCHAR(200),
  data_ricezione_portale VARCHAR(200),
  doc_contabilizza_genpcc VARCHAR(200),
  rudoc_registrazione_anno INTEGER,
  rudoc_registrazione_numero INTEGER,
  rudoc_registrazione_data TIMESTAMP WITHOUT TIME ZONE,
  cod_cdc_doc VARCHAR(200),
  desc_cdc_doc VARCHAR(500),
  cod_cdr_doc VARCHAR(200),
  desc_cdr_doc VARCHAR(500),
  data_operazione_pagamentoincasso VARCHAR(500),
  pagataincassata VARCHAR(500),
  note_pagamentoincasso VARCHAR(500),
  cod_tipo_splitrev VARCHAR(200),
  desc_tipo_splitrev VARCHAR(200),
  stato_liquidazione VARCHAR(200),
  arrotondamento NUMERIC,
  cod_siope_tipo_debito_subdoc VARCHAR(200),
  desc_siope_tipo_debito_subdoc VARCHAR(500),
  desc_siope_tipo_deb_bnkit_sub VARCHAR(500),
  cod_siope_ass_motiv_subdoc VARCHAR(200),
  desc_siope_ass_motiv_subdoc VARCHAR(500),
  desc_siope_ass_motiv_bnkit_sub VARCHAR(500),
  cod_siope_scad_motiv_subdoc VARCHAR(200),
  desc_siope_scad_motiv_subdoc VARCHAR(500),
  desc_siope_scad_moti_bnkit_sub VARCHAR(500),
  sdi_lotto_siope_doc VARCHAR(200),
  cod_siope_tipo_doc VARCHAR(200),
  desc_siope_tipo_doc VARCHAR(500),
  desc_siope_tipo_bnkit_doc VARCHAR(500),
  cod_siope_tipo_analogico_doc VARCHAR(200),
  desc_siope_tipo_analogico_doc VARCHAR(500),
  desc_siope_tipo_ana_bnkit_doc VARCHAR(500),
  data_ins_atto_allegato TIMESTAMP WITHOUT TIME ZONE,
  data_completa_atto_allegato TIMESTAMP WITHOUT TIME ZONE,
  data_convalida_atto_allegato TIMESTAMP WITHOUT TIME ZONE,
  data_sosp_atto_allegato TIMESTAMP WITHOUT TIME ZONE,
  data_riattiva_atto_allegato TIMESTAMP WITHOUT TIME ZONE,
  causale_sosp_atto_allegato VARCHAR(250),
  data_storico TIMESTAMP WITHOUT TIME ZONE not null default now(),
  doc_id INTEGER
)
WITH (oids = false);

alter table if exists
siac.siac_dwh_st_documento_spesa OWNER to siac;

begin;
  insert into siac_d_gestione_tipo
  (
  	gestione_tipo_code,
    gestione_tipo_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  select 'ANNO_STORICO_DWH_DOC_SPESA_ATTIVO',
         'Impostazione anno storico in scarico dwh documenti di spesa',
         now(),
         'SIAC-7518',
         ente.ente_Proprietario_id
  from siac_t_ente_proprietario ente
  where ente.ente_proprietario_id =2
  and   not exists
  (
  select 1
  from siac_d_gestione_tipo tipo
  where tipo.ente_proprietario_id=ente.ente_proprietario_id
  and   tipo.gestione_tipo_code='ANNO_STORICO_DWH_DOC_SPESA_ATTIVO'
  );

  insert into siac_d_gestione_livello
  (
  	gestione_livello_code,
    gestione_livello_desc,
    gestione_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  select
	'2018_'||tipo.gestione_tipo_code,
    tipo.gestione_tipo_desc,
    tipo.gestione_tipo_id,
    now(),
    tipo.login_operazione,
    tipo.ente_proprietario_id
  from siac_d_gestione_tipo tipo,siac_t_ente_proprietario ente
  where ente.ente_Proprietario_id =2
  and   tipo.ente_proprietario_id=ente.ente_proprietario_id
  and   tipo.gestione_tipo_code='ANNO_STORICO_DWH_DOC_SPESA_ATTIVO'
  and   not exists
  (
  select 1
  from siac_d_gestione_livello liv
  where liv.ente_proprietario_id=ente.ente_proprietario_id
  and   liv.gestione_tipo_id=tipo.gestione_tipo_id
  and   liv.gestione_livello_code='2018_'||tipo.gestione_tipo_code
  );


  insert into siac_d_gestione_tipo
  (
  	gestione_tipo_code,
    gestione_tipo_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  select 'CARICA_STORICO_DWH_DOC_SPESA_ATTIVO',
         'Attivazione caricamento dati di storico in scarico dwh documenti di spesa',
         now(),
         'SIAC-7518',
         ente.ente_Proprietario_id
  from siac_t_ente_proprietario ente
  where ente.ente_proprietario_id =2
  and   not exists
  (
  select 1
  from siac_d_gestione_tipo tipo
  where tipo.ente_proprietario_id=ente.ente_proprietario_id
  and   tipo.gestione_tipo_code='CARICA_STORICO_DWH_DOC_SPESA_ATTIVO'
  );

  insert into siac_d_gestione_livello
  (
  	gestione_livello_code,
    gestione_livello_desc,
    gestione_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  select
	tipo.gestione_tipo_code,
    tipo.gestione_tipo_desc,
    tipo.gestione_tipo_id,
    now(),
    tipo.login_operazione,
    tipo.ente_proprietario_id
  from siac_d_gestione_tipo tipo,siac_t_ente_proprietario ente
  where ente.ente_Proprietario_id =2
  and   tipo.ente_proprietario_id=ente.ente_proprietario_id
  and   tipo.gestione_tipo_code='CARICA_STORICO_DWH_DOC_SPESA_ATTIVO'
  and   not exists
  (
  select 1
  from siac_d_gestione_livello liv
  where liv.ente_proprietario_id=ente.ente_proprietario_id
  and   liv.gestione_tipo_id=tipo.gestione_tipo_id
  and   liv.gestione_livello_code=tipo.gestione_tipo_code
  );


  insert into siac_d_gestione_tipo
  (
  	gestione_tipo_code,
    gestione_tipo_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  select 'ELABORA_STORICO_DWH_DOC_SPESA_ATTIVO',
         'Attivazione elaborazione caricamento dati di storico documenti di spesa per dwh',
         now(),
         'SIAC-7518',
         ente.ente_Proprietario_id
  from siac_t_ente_proprietario ente
  where ente.ente_proprietario_id=2
  and   not exists
  (
  select 1
  from siac_d_gestione_tipo tipo
  where tipo.ente_proprietario_id=ente.ente_proprietario_id
  and   tipo.gestione_tipo_code='ELABORA_STORICO_DWH_DOC_SPESA_ATTIVO'
  );

  insert into siac_d_gestione_livello
  (
  	gestione_livello_code,
    gestione_livello_desc,
    gestione_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  select
	tipo.gestione_tipo_code,
    tipo.gestione_tipo_desc,
    tipo.gestione_tipo_id,
    now(),
    tipo.login_operazione,
    tipo.ente_proprietario_id
  from siac_d_gestione_tipo tipo,siac_t_ente_proprietario ente
  where ente.ente_Proprietario_id =2
  and   tipo.ente_proprietario_id=ente.ente_proprietario_id
  and   tipo.gestione_tipo_code='ELABORA_STORICO_DWH_DOC_SPESA_ATTIVO'
  and   not exists
  (
  select 1
  from siac_d_gestione_livello liv
  where liv.ente_proprietario_id=ente.ente_proprietario_id
  and   liv.gestione_tipo_id=tipo.gestione_tipo_id
  and   liv.gestione_livello_code=tipo.gestione_tipo_code
  );