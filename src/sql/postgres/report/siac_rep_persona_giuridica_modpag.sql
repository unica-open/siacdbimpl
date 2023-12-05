/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_rep_persona_giuridica_modpag (
  soggetto_id INTEGER,
  soggetto_desc VARCHAR,
  soggetto_ricevente_id INTEGER,
  soggetto_ricevente_desc VARCHAR,
  soggetto_ricevente_cod_fis VARCHAR,
  soggetto_ricevente_piva VARCHAR,
  modpag_id INTEGER,
  accredito_tipo_id INTEGER,
  accredito_tipo_code VARCHAR,
  accredito_tipo_desc VARCHAR,
  modpag_stato_code VARCHAR,
  modpag_stato_desc VARCHAR,
  note VARCHAR,
  accredito_ricevente_tipo_code VARCHAR,
  accredito_ricevente_tipo_desc VARCHAR,
  ente_proprietario INTEGER,
  utente VARCHAR,
  soggetto_code VARCHAR,
  quietanzante VARCHAR,
  quietanzante_codice_fiscale VARCHAR,
  iban VARCHAR,
  bic VARCHAR,
  conto_corrente VARCHAR,
  mp_data_scadenza TIMESTAMP(0) WITHOUT TIME ZONE,
  data_scadenza_cessione TIMESTAMP(0) WITHOUT TIME ZONE
) 
WITH (oids = false);

COMMENT ON COLUMN siac.siac_rep_persona_giuridica_modpag.mp_data_scadenza
IS 'data scadenza dlla modalità di pagamento';

COMMENT ON COLUMN siac.siac_rep_persona_giuridica_modpag.data_scadenza_cessione
IS 'data di scadenza della forma di pagamento relativa alla cessione';
