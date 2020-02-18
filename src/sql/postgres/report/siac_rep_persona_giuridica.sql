/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_rep_persona_giuridica (
  ambito_id INTEGER,
  soggetto_code VARCHAR,
  codice_fiscale VARCHAR,
  codice_fiscale_estero VARCHAR,
  partita_iva VARCHAR,
  soggetto_desc VARCHAR,
  soggetto_tipo_code VARCHAR,
  soggetto_tipo_desc VARCHAR,
  forma_giuridica_cat_id VARCHAR,
  forma_giuridica_desc VARCHAR,
  forma_giuridica_istat_codice VARCHAR,
  soggetto_id INTEGER,
  stato VARCHAR,
  classe_soggetto VARCHAR,
  ente_proprietario INTEGER,
  utente VARCHAR
) 
WITH (oids = false);