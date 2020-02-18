/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_dwh_soggetto (
  ente_proprietario_id INTEGER,
  ente_denominazione VARCHAR(500),
  soggetto_id INTEGER,
  cod_soggetto VARCHAR(200),
  tipo_soggetto VARCHAR(500),
  stato_soggetto VARCHAR(500),
  ragione_sociale VARCHAR(500),
  p_iva VARCHAR(500),
  cf VARCHAR(16),
  cf_estero VARCHAR(500),
  nome VARCHAR(500),
  cognome VARCHAR(500),
  sesso VARCHAR(1),
  data_nascita TIMESTAMP WITHOUT TIME ZONE,
  comune_nascita VARCHAR(500),
  codistat_comune_nascita VARCHAR(500),
  codcatastale_comune_nascita VARCHAR(500),
  provincia_nascita VARCHAR(500),
  nazione_nascita VARCHAR(500),
  indirizzo_principale VARCHAR,
  cap_indirizzo_principale VARCHAR(10),
  comune_indirizzo_principale VARCHAR(500),
  codistat_comune_ind_princ VARCHAR(500),
  codcatastale_comune_ind_princ VARCHAR(500),
  provincia_indirizzo_principale VARCHAR(500),
  nazione_indirizzo_principale VARCHAR(500),
  indirizzo_domicilio_fiscale VARCHAR,
  cap_domicilio_fiscale VARCHAR(10),
  comune_domicilio_fiscale VARCHAR(500),
  codistat_comune_domfiscale VARCHAR(500),
  codcatastale_comune_domfiscale VARCHAR(500),
  provincia_domicilio_fiscale VARCHAR(500),
  nazione_domicilio_fiscale VARCHAR(500),
  indirizzo_residenza VARCHAR,
  cap_residenza VARCHAR(10),
  comune_residenza VARCHAR(500),
  codistat_comune_residenza VARCHAR(500),
  codcatastale_comune_residenza VARCHAR(500),
  provincia_residenza VARCHAR(500),
  nazione_residenza VARCHAR(500),
  indirizzo_sede_legale VARCHAR,
  cap_sede_legale VARCHAR(10),
  comune_sede_legale VARCHAR(500),
  codistat_comune_sedelegale VARCHAR(500),
  codcatastale_comune_sedelegale VARCHAR(500),
  provincia_sede_legale VARCHAR(500),
  nazione_sede_legale VARCHAR(500),
  indirizzo_sede_amministrativa VARCHAR,
  cap_sede_amministrativa VARCHAR(10),
  comune_sede_amministrativa VARCHAR(500),
  codistat_comune_sede_amm VARCHAR(500),
  codcatastale_comune_sede_amm VARCHAR(500),
  provincia_sede_amministrativa VARCHAR(500),
  nazione_sede_amministrativa VARCHAR(500),
  indirizzo_sede_operativa VARCHAR,
  cap_sede_operativa VARCHAR(10),
  comune_sede_operativa VARCHAR(500),
  codistat_comune_sede_oper VARCHAR(500),
  codcatastale_comune_sede_oper VARCHAR(500),
  provincia_sede_operativa VARCHAR(500),
  nazione_sede_operativa VARCHAR(500),
  telefono VARCHAR(500),
  cellulare VARCHAR(500),
  fax VARCHAR(500),
  email VARCHAR(500),
  pec VARCHAR(500),
  sito_web VARCHAR(500),
  soggetto_recapito VARCHAR(500),
  avviso VARCHAR(1),
  note VARCHAR(500),
  matricola_hrspi VARCHAR(500),
  classe_soggetto VARCHAR(500),
  sede_secondaria VARCHAR(1),
  soggetto_id_principale INTEGER,
  codice_soggetto_principale VARCHAR(200),
  soggetto_principale VARCHAR(500),
  -- 05.12.2018 Sofia SIAC-6261
  soggetto_tipo_fonte_durc varchar(1),
  soggetto_fonte_durc_automatica varchar(500),
  soggetto_note_durc varchar(500),
  soggetto_fine_validita_durc TIMESTAMP WITHOUT TIME ZONE,
  soggetto_fonte_durc_manuale_code varchar(200),
  soggetto_fonte_durc_manuale_desc varchar(500)
  -- 05.12.2018 Sofia SIAC-6261
)
WITH (oids = false);

COMMENT ON COLUMN siac.siac_dwh_soggetto.cod_soggetto
IS 'siac_t_soggetto.soggetto_code';

COMMENT ON COLUMN siac.siac_dwh_soggetto.tipo_soggetto
IS 'siac_d_soggetto_tipo.soggetto_tipo_desc tramite siac_r_soggetto_tipo';

COMMENT ON COLUMN siac.siac_dwh_soggetto.stato_soggetto
IS 'siac_t_soggetto_stato.soggetto_stato_desc tramite siac_r_soggetto_stato';

COMMENT ON COLUMN siac.siac_dwh_soggetto.ragione_sociale
IS 'siac_t_persona_giuridica.ragione_sociale';

COMMENT ON COLUMN siac.siac_dwh_soggetto.p_iva
IS 'siac_t_soggetto.p_iva';

COMMENT ON COLUMN siac.siac_dwh_soggetto.cf
IS 'siac_t_soggetto.cod_fiscale';

COMMENT ON COLUMN siac.siac_dwh_soggetto.cf_estero
IS 'siac_t_soggetto.cod_fiscale_estero';

COMMENT ON COLUMN siac.siac_dwh_soggetto.nome
IS 'siac_t_persona_fisica.nome';

COMMENT ON COLUMN siac.siac_dwh_soggetto.cognome
IS 'siac_t_persona_fisica.cognome';

COMMENT ON COLUMN siac.siac_dwh_soggetto.sesso
IS 'siac_t_persona_fisica.sesso';

COMMENT ON COLUMN siac.siac_dwh_soggetto.data_nascita
IS 'siac_t_persona_fisica.nascita_data';

COMMENT ON COLUMN siac.siac_dwh_soggetto.comune_nascita
IS 'siac_t_comune.comune_desc';

COMMENT ON COLUMN siac.siac_dwh_soggetto.codistat_comune_nascita
IS 'siac_t_comune.comune_istat_code';

COMMENT ON COLUMN siac.siac_dwh_soggetto.codcatastale_comune_nascita
IS 'siac_t_comune.comune_belfiore_catastale_code';

COMMENT ON COLUMN siac.siac_dwh_soggetto.provincia_nascita
IS 'siac_t_provincia.provincia_desc tramite siac_r_comune_provincia';

COMMENT ON COLUMN siac.siac_dwh_soggetto.nazione_nascita
IS 'siac_t_nazione.nazione_desc tramite siac_t_comune.nazione_id';

COMMENT ON COLUMN siac.siac_dwh_soggetto.indirizzo_principale
IS 'con siac_t_indirizzo_soggetto.principale=''S'' concatenazione di  siac_d_via_tipo.via_tipo_desc siac_t_indirizzo_soggetto.toponimo siac_t_indirizzo_soggetto.num_civico '','' ''frazione '' || siac_t_indirizzo_soggetto.frazione  '','' ''interno '' || siac_t_indirizzo_soggetto.interno  ';

COMMENT ON COLUMN siac.siac_dwh_soggetto.cap_indirizzo_principale
IS 'siac_t_indirizzo_soggetto.zip_code';

COMMENT ON COLUMN siac.siac_dwh_soggetto.comune_indirizzo_principale
IS 'siac_t_comune.comune_desc';

COMMENT ON COLUMN siac.siac_dwh_soggetto.codistat_comune_ind_princ
IS 'siac_t_comune.comune_istat_code';

COMMENT ON COLUMN siac.siac_dwh_soggetto.codcatastale_comune_ind_princ
IS 'siac_t_comune.comune_belfiore_catastale_code';

COMMENT ON COLUMN siac.siac_dwh_soggetto.provincia_indirizzo_principale
IS 'siac_t_provincia.provincia_desc tramite siac_r_comune_provincia';

COMMENT ON COLUMN siac.siac_dwh_soggetto.nazione_indirizzo_principale
IS 'siac_t_nazione.nazione_desc tramite siac_t_comune.nazione_id';

COMMENT ON COLUMN siac.siac_dwh_soggetto.indirizzo_domicilio_fiscale
IS 'con siac_t_indirizzo_soggetto.principale=''S'' concatenazione di  siac_d_via_tipo.via_tipo_desc siac_t_indirizzo_soggetto.toponimo siac_t_indirizzo_soggetto.num_civico '','' ''frazione '' || siac_t_indirizzo_soggetto.frazione  '','' ''interno '' || siac_t_indirizzo_soggetto.interno';

COMMENT ON COLUMN siac.siac_dwh_soggetto.cap_domicilio_fiscale
IS 'siac_t_indirizzo_soggetto.zip_code';

COMMENT ON COLUMN siac.siac_dwh_soggetto.comune_domicilio_fiscale
IS 'siac_t_comune.comune_desc';

COMMENT ON COLUMN siac.siac_dwh_soggetto.codistat_comune_domfiscale
IS 'siac_t_comune.comune_istat_code';

COMMENT ON COLUMN siac.siac_dwh_soggetto.codcatastale_comune_domfiscale
IS 'siac_t_comune.comune_belfiore_catastale_code';

COMMENT ON COLUMN siac.siac_dwh_soggetto.provincia_domicilio_fiscale
IS 'siac_t_provincia.provincia_desc tramite siac_r_comune_provincia';

COMMENT ON COLUMN siac.siac_dwh_soggetto.nazione_domicilio_fiscale
IS 'siac_t_nazione.nazione_desc tramite siac_t_comune.nazione_id';

COMMENT ON COLUMN siac.siac_dwh_soggetto.indirizzo_residenza
IS 'con siac_t_indirizzo_soggetto.principale=''S'' concatenazione di  siac_d_via_tipo.via_tipo_desc siac_t_indirizzo_soggetto.toponimo siac_t_indirizzo_soggetto.num_civico '','' ''frazione '' || siac_t_indirizzo_soggetto.frazione  '','' ''interno '' || siac_t_indirizzo_soggetto.interno';

COMMENT ON COLUMN siac.siac_dwh_soggetto.cap_residenza
IS 'siac_t_indirizzo_soggetto.zip_code';

COMMENT ON COLUMN siac.siac_dwh_soggetto.comune_residenza
IS 'siac_t_comune.comune_desc';

COMMENT ON COLUMN siac.siac_dwh_soggetto.codistat_comune_residenza
IS 'siac_t_comune.comune_istat_code';

COMMENT ON COLUMN siac.siac_dwh_soggetto.codcatastale_comune_residenza
IS 'siac_t_comune.comune_belfiore_catastale_code';

COMMENT ON COLUMN siac.siac_dwh_soggetto.provincia_residenza
IS 'siac_t_provincia.provincia_desc tramite siac_r_comune_provincia';

COMMENT ON COLUMN siac.siac_dwh_soggetto.nazione_residenza
IS 'siac_t_nazione.nazione_desc tramite siac_t_comune.nazione_id';

COMMENT ON COLUMN siac.siac_dwh_soggetto.indirizzo_sede_legale
IS 'con siac_t_indirizzo_soggetto.principale=''S'' concatenazione di  siac_d_via_tipo.via_tipo_desc siac_t_indirizzo_soggetto.toponimo siac_t_indirizzo_soggetto.num_civico '','' ''frazione '' || siac_t_indirizzo_soggetto.frazione  '','' ''interno '' || siac_t_indirizzo_soggetto.interno';

COMMENT ON COLUMN siac.siac_dwh_soggetto.cap_sede_legale
IS 'siac_t_indirizzo_soggetto.zip_code';

COMMENT ON COLUMN siac.siac_dwh_soggetto.comune_sede_legale
IS 'siac_t_comune.comune_desc';

COMMENT ON COLUMN siac.siac_dwh_soggetto.codistat_comune_sedelegale
IS 'siac_t_comune.comune_istat_code';

COMMENT ON COLUMN siac.siac_dwh_soggetto.codcatastale_comune_sedelegale
IS 'siac_t_comune.comune_belfiore_catastale_code';

COMMENT ON COLUMN siac.siac_dwh_soggetto.provincia_sede_legale
IS 'siac_t_provincia.provincia_desc tramite siac_r_comune_provincia';

COMMENT ON COLUMN siac.siac_dwh_soggetto.nazione_sede_legale
IS 'siac_t_nazione.nazione_desc tramite siac_t_comune.nazione_id';

COMMENT ON COLUMN siac.siac_dwh_soggetto.indirizzo_sede_amministrativa
IS 'con siac_t_indirizzo_soggetto.principale=''S'' concatenazione di  siac_d_via_tipo.via_tipo_desc siac_t_indirizzo_soggetto.toponimo siac_t_indirizzo_soggetto.num_civico '','' ''frazione '' || siac_t_indirizzo_soggetto.frazione  '','' ''interno '' || siac_t_indirizzo_soggetto.interno';

COMMENT ON COLUMN siac.siac_dwh_soggetto.cap_sede_amministrativa
IS 'siac_t_indirizzo_soggetto.zip_code';

COMMENT ON COLUMN siac.siac_dwh_soggetto.comune_sede_amministrativa
IS 'siac_t_comune.comune_desc';

COMMENT ON COLUMN siac.siac_dwh_soggetto.codistat_comune_sede_amm
IS 'siac_t_comune.comune_istat_code';

COMMENT ON COLUMN siac.siac_dwh_soggetto.codcatastale_comune_sede_amm
IS 'siac_t_comune.comune_belfiore_catastale_code';

COMMENT ON COLUMN siac.siac_dwh_soggetto.provincia_sede_amministrativa
IS 'siac_t_provincia.provincia_desc tramite siac_r_comune_provincia';

COMMENT ON COLUMN siac.siac_dwh_soggetto.nazione_sede_amministrativa
IS 'siac_t_nazione.nazione_desc tramite siac_t_comune.nazione_id';

COMMENT ON COLUMN siac.siac_dwh_soggetto.indirizzo_sede_operativa
IS 'con siac_t_indirizzo_soggetto.principale=''S'' concatenazione di  siac_d_via_tipo.via_tipo_desc siac_t_indirizzo_soggetto.toponimo siac_t_indirizzo_soggetto.num_civico '','' ''frazione '' || siac_t_indirizzo_soggetto.frazione  '','' ''interno '' || siac_t_indirizzo_soggetto.interno';

COMMENT ON COLUMN siac.siac_dwh_soggetto.cap_sede_operativa
IS 'siac_t_indirizzo_soggetto.zip_code';

COMMENT ON COLUMN siac.siac_dwh_soggetto.comune_sede_operativa
IS 'siac_t_comune.comune_desc';

COMMENT ON COLUMN siac.siac_dwh_soggetto.codistat_comune_sede_oper
IS 'siac_t_comune.comune_istat_code';

COMMENT ON COLUMN siac.siac_dwh_soggetto.codcatastale_comune_sede_oper
IS 'siac_t_comune.comune_belfiore_catastale_code';

COMMENT ON COLUMN siac.siac_dwh_soggetto.provincia_sede_operativa
IS 'siac_t_provincia.provincia_desc tramite siac_r_comune_provincia';

COMMENT ON COLUMN siac.siac_dwh_soggetto.nazione_sede_operativa
IS 'siac_t_nazione.nazione_desc tramite siac_t_comune.nazione_id';

COMMENT ON COLUMN siac.siac_dwh_soggetto.telefono
IS 'siac_t_recapito_soggetto.recapito_desc con recapito_modo_id = siac_d_recapito_modo.recapito_modo_id dove siac_d_recapito_modo.recapito_modo_code=''telefono''';

COMMENT ON COLUMN siac.siac_dwh_soggetto.cellulare
IS 'siac_t_recapito_soggetto.recapito_desc con recapito_modo_id = siac_d_recapito_modo.recapito_modo_id dove siac_d_recapito_modo.recapito_modo_code=''cellulare''';

COMMENT ON COLUMN siac.siac_dwh_soggetto.fax
IS 'siac_t_recapito_soggetto.recapito_desc con recapito_modo_id = siac_d_recapito_modo.recapito_modo_id dove siac_d_recapito_modo.recapito_modo_code=''fax''';

COMMENT ON COLUMN siac.siac_dwh_soggetto.email
IS 'siac_t_recapito_soggetto.recapito_desc con recapito_modo_id = siac_d_recapito_modo.recapito_modo_id dove siac_d_recapito_modo.recapito_modo_code=''email''';

COMMENT ON COLUMN siac.siac_dwh_soggetto.pec
IS 'siac_t_recapito_soggetto.recapito_desc con recapito_modo_id = siac_d_recapito_modo.recapito_modo_id dove siac_d_recapito_modo.recapito_modo_code=''PEC''';

COMMENT ON COLUMN siac.siac_dwh_soggetto.sito_web
IS 'siac_t_recapito_soggetto.recapito_desc con recapito_modo_id = siac_d_recapito_modo.recapito_modo_id dove siac_d_recapito_modo.recapito_modo_code=''sito''';

COMMENT ON COLUMN siac.siac_dwh_soggetto.soggetto_recapito
IS 'siac_t_recapito_soggetto.recapito_desc con recapito_modo_id = siac_d_recapito_modo.recapito_modo_id dove siac_d_recapito_modo.recapito_modo_code=''soggetto''';

COMMENT ON COLUMN siac.siac_dwh_soggetto.avviso
IS 'se almeno uno dei recapiti ha siac_t_recapito_soggetto.avviso=''S''';

COMMENT ON COLUMN siac.siac_dwh_soggetto.note
IS 'attributo NoteSoggetto siac_t_attr - siac_r_soggetto_attr';

COMMENT ON COLUMN siac.siac_dwh_soggetto.matricola_hrspi
IS 'attributo Matricola siac_t_attr - siac_r_soggetto_attr';

COMMENT ON COLUMN siac.siac_dwh_soggetto.classe_soggetto
IS 'siac_d_soggetto_classe.soggetto_classe_desc tramite siac_r_soggetto_classe';

COMMENT ON COLUMN siac.siac_dwh_soggetto.sede_secondaria
IS 'S'' se soggetto_id = siac_r_soggetto_relaz.soggetto_id_a con siac_d_relaz_tipo=''SEDE_SECONDARIA';

COMMENT ON COLUMN siac.siac_dwh_soggetto.codice_soggetto_principale
IS 'siac.siac_t_soggetto.soggetto_code. Se soggetto_id = siac_r_soggetto_relaz.soggetto_id_a con siac_d_relaz_tipo = ''SEDE_SECONDARIA'' considerare siac_r_soggetto_relaz.soggetto_id_da';

COMMENT ON COLUMN siac.siac_dwh_soggetto.soggetto_principale
IS 'siac_t_persona_giuridica.ragione_sociale (PG,PGI) o siac.siac_t_persona_fisica.tpf.nome||'' ''||tpf.cognome (PF,PFI). se soggetto_id = siac_r_soggetto_relaz.soggetto_id_a con siac_d_relaz_tipo = ''SEDE_SECONDARIA'' considerare siac_r_soggetto_relaz.soggetto_id_da';