/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- Table: mif_t_emap_hrer

-- DROP TABLE mif_t_emap_hrer;

CREATE TABLE mif_t_emap_hrer
(
  flusso_elab_mif_id bigint,
  n_row bigint,
  codice_flusso character varying(80),
  tipo_record character varying(2),
  data_ora_flusso character varying(19),
  tipo_flusso character(1),
  codice_abi_bt character varying(5),
  codice_ente_bt character varying(7),
  tipo_servizio character varying(8),
  aid character varying(6),
  num_ricevute character varying(7),
  id bigserial NOT NULL,
  ente_proprietario_id smallint,
  CONSTRAINT mif_t_emap_hrer_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE mif_t_emap_hrer
  OWNER TO siac;

  -- Table: mif_t_emap_rr

-- DROP TABLE mif_t_emap_rr;

CREATE TABLE mif_t_emap_rr
(
  flusso_elab_mif_id bigint,
  n_row bigint,
  codice_flusso character varying(80),
  tipo_record character varying(2),
  progressivo_ricevuta character varying(7),
  id_tipo character varying(2),
  data_messaggio character varying(8),
  ora_messaggio character varying(4),
  firma_nome character varying(70),
  firma_data character varying(94),
  firma_ora character varying(4),
  esito_derivato character varying(2),
  data_ora_creazione_ricevuta character varying(19),
  qualificatore character varying(3),
  codice_abi_bt character varying(5),
  codice_ente character varying(11),
  descrizione_ente character varying(30),
  codice_ente_bt character varying(7),
  data_ora_ricevuta character varying(19),
  numero_documento character varying(7),
  codice_funzione character varying(2),
  numero_ordinativo character varying(7),
  progressivo_ordinativo character varying(7),
  data_ordinativo character varying(10),
  esercizio character varying(4),
  codice_esito character varying(2),
  descrizione_esito character varying(70),
  data_pagamento character varying(10),
  importo_ordinativo character varying(15),
  codice_pagamento character varying(2),
  importo_ritenute character varying(15),
  flag_copertura character varying(1),
  valuta_beneficiario character varying(10),
  valuta_ente character varying(10),
  abi_beneficiario character varying(5),
  cab_beneficiario character varying(5),
  cc_beneficiario character varying(12),
  coordinate_iban character varying(34),
  carico_bollo character varying(1),
  importo_bollo character varying(7),
  carico_commisioni character varying(1),
  importo_commissioni character varying(7),
  carico_spese character varying(1),
  importo_spese character varying(7),
  num_assegno character varying(20),
  data_emissione_assegno character varying(10),
  data_estinzione_assegno character varying(10),
  codice_versamento character varying(5),
  numero_pratica character varying(16),
  causale_pratica character varying(45),
  num_proposta_reversale character varying(7),
  nome_cognome character varying(140),
  indirizzo character varying(30),
  cap character varying(5),
  localita character varying(30),
  provincia character varying(2),
  partita_iva character varying(11),
  codice_fiscale character varying(16),
  causale character varying(370),
  num_pagamento_funzionario_delegato character varying(7),
  progressivo_pagamento_funzionario_delegato character varying(7),
  codice_ente_beneficiario character varying(7),
  descrizione character varying(30),
  id bigserial NOT NULL,
  ente_proprietario_id smallint,
  cro1 character varying(11),
  cro2 character varying(23),
  CONSTRAINT mif_t_emap_rr_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE mif_t_emap_rr
  OWNER TO siac;

-- Table: mif_t_emap_dr

-- DROP TABLE mif_t_emap_dr;

CREATE TABLE mif_t_emap_dr
(
  flusso_elab_mif_id bigint,
  n_row bigint,
  codice_flusso character varying(80),
  tipo_record character varying(2),
  progressivo_ricevuta character varying(7),
  num_ricevuta character varying(7),
  importo_ricevuta character varying(15),
  id bigserial NOT NULL,
  ente_proprietario_id smallint,
  CONSTRAINT mif_t_emap_dr_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE mif_t_emap_dr
  OWNER TO siac;

  
-- Table: mif_t_emat_dr

-- DROP TABLE mif_t_emat_dr;

CREATE TABLE mif_t_emat_dr
(
  flusso_elab_mif_id bigint,
  n_row bigint,
  codice_flusso character varying(80),
  tipo_record character varying(2),
  progressivo_ricevuta character varying(7),
  num_ricevuta character varying(7),
  importo_ricevuta character varying(15),
  id bigserial NOT NULL,
  ente_proprietario_id smallint,
  CONSTRAINT mif_t_emat_dr_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE mif_t_emat_dr
  OWNER TO siac;

-- Table: mif_t_emat_hrer

-- DROP TABLE mif_t_emat_hrer;

CREATE TABLE mif_t_emat_hrer
(
  flusso_elab_mif_id bigint,
  n_row bigint,
  codice_flusso character varying(80),
  tipo_record character varying(2),
  data_ora_flusso character varying(19),
  tipo_flusso character(1),
  codice_abi_bt character varying(5),
  codice_ente_bt character varying(7),
  tipo_servizio character varying(8),
  aid character varying(6),
  num_ricevute character varying(7),
  id bigserial NOT NULL,
  ente_proprietario_id smallint,
  CONSTRAINT mif_t_emat_hrer_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE mif_t_emat_hrer
  OWNER TO siac;

-- Table: mif_t_emat_rr

-- DROP TABLE mif_t_emat_rr;

CREATE TABLE mif_t_emat_rr
(
  flusso_elab_mif_id bigint,
  n_row bigint,
  codice_flusso character varying(80),
  tipo_record character varying(2),
  progressivo_ricevuta character varying(7),
  id_tipo character varying(2),
  data_messaggio character varying(8),
  ora_messaggio character varying(4),
  firma_nome character varying(70),
  firma_data character varying(94),
  firma_ora character varying(4),
  esito_derivato character varying(2),
  data_ora_creazione_ricevuta character varying(19),
  qualificatore character varying(3),
  codice_abi_bt character varying(5),
  codice_ente character varying(11),
  descrizione_ente character varying(30),
  codice_ente_bt character varying(7),
  data_ora_ricevuta character varying(19),
  numero_documento character varying(7),
  codice_funzione character varying(2),
  numero_ordinativo character varying(7),
  progressivo_ordinativo character varying(7),
  data_ordinativo character varying(10),
  esercizio character varying(4),
  codice_esito character varying(2),
  descrizione_esito character varying(70),
  data_pagamento character varying(10),
  importo_ordinativo character varying(15),
  codice_pagamento character varying(2),
  importo_ritenute character varying(15),
  flag_copertura character varying(1),
  valuta_beneficiario character varying(10),
  valuta_ente character varying(10),
  abi_beneficiario character varying(5),
  cab_beneficiario character varying(5),
  cc_beneficiario character varying(12),
  coordinate_iban character varying(34),
  carico_bollo character varying(1),
  importo_bollo character varying(7),
  carico_commisioni character varying(1),
  importo_commissioni character varying(7),
  carico_spese character varying(1),
  importo_spese character varying(7),
  num_assegno character varying(20),
  data_emissione_assegno character varying(10),
  data_estinzione_assegno character varying(10),
  codice_versamento character varying(5),
  numero_pratica character varying(16),
  causale_pratica character varying(45),
  num_proposta_reversale character varying(7),
  nome_cognome character varying(140),
  indirizzo character varying(30),
  cap character varying(5),
  localita character varying(30),
  provincia character varying(2),
  partita_iva character varying(11),
  codice_fiscale character varying(16),
  causale character varying(370),
  num_pagamento_funzionario_delegato character varying(7),
  progressivo_pagamento_funzionario_delegato character varying(7),
  codice_ente_beneficiario character varying(7),
  descrizione character varying(30),
  id bigserial NOT NULL,
  ente_proprietario_id smallint,
  cro character varying(300),
  CONSTRAINT mif_t_emat_rr_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE mif_t_emat_rr
  OWNER TO siac;

-- Table: mif_t_emfe_dr

-- DROP TABLE mif_t_emfe_dr;

CREATE TABLE mif_t_emfe_dr
(
  flusso_elab_mif_id bigint,
  n_row bigint,
  codice_flusso character varying(80),
  tipo_record character varying(2),
  progressivo_ricevuta character varying(7),
  num_ricevuta character varying(7),
  importo_ricevuta character varying(15),
  id bigserial NOT NULL,
  ente_proprietario_id smallint,
  CONSTRAINT mif_t_emfe_dr_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE mif_t_emfe_dr
  OWNER TO siac;

-- Table: mif_t_emfe_hrer

-- DROP TABLE mif_t_emfe_hrer;

CREATE TABLE mif_t_emfe_hrer
(
  flusso_elab_mif_id bigint,
  n_row bigint,
  codice_flusso character varying(80),
  tipo_record character varying(2),
  data_ora_flusso character varying(19),
  tipo_flusso character(1),
  codice_abi_bt character varying(5),
  codice_ente_bt character varying(7),
  tipo_servizio character varying(8),
  aid character varying(6),
  num_ricevute character varying(7),
  id bigserial NOT NULL,
  ente_proprietario_id smallint,
  CONSTRAINT mif_t_emfe_hrer_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE mif_t_emfe_hrer
  OWNER TO siac;

-- Table: mif_t_emfe_rr

-- DROP TABLE mif_t_emfe_rr;

CREATE TABLE mif_t_emfe_rr
(
  flusso_elab_mif_id bigint,
  n_row bigint,
  codice_flusso character varying(80),
  tipo_record character varying(2),
  progressivo_ricevuta character varying(7),
  id_tipo character varying(2),
  data_messaggio character varying(8),
  ora_messaggio character varying(4),
  firma_nome character varying(70),
  firma_data character varying(94),
  firma_ora character varying(4),
  esito_derivato character varying(2),
  data_ora_creazione_ricevuta character varying(19),
  qualificatore character varying(3),
  codice_abi_bt character varying(5),
  codice_ente character varying(11),
  descrizione_ente character varying(30),
  codice_ente_bt character varying(7),
  data_ora_ricevuta character varying(19),
  numero_documento character varying(7),
  codice_funzione character varying(2),
  numero_ordinativo character varying(7),
  progressivo_ordinativo character varying(7),
  data_ordinativo character varying(10),
  esercizio character varying(4),
  codice_esito character varying(2),
  descrizione_esito character varying(70),
  data_pagamento character varying(10),
  importo_ordinativo character varying(15),
  codice_pagamento character varying(2),
  importo_ritenute character varying(15),
  flag_copertura character varying(1),
  valuta_beneficiario character varying(10),
  valuta_ente character varying(10),
  abi_beneficiario character varying(5),
  cab_beneficiario character varying(5),
  cc_beneficiario character varying(12),
  coordinate_iban character varying(34),
  carico_bollo character varying(1),
  importo_bollo character varying(7),
  carico_commisioni character varying(1),
  importo_commissioni character varying(7),
  carico_spese character varying(1),
  importo_spese character varying(7),
  num_assegno character varying(20),
  data_emissione_assegno character varying(10),
  data_estinzione_assegno character varying(10),
  codice_versamento character varying(5),
  numero_pratica character varying(16),
  causale_pratica character varying(45),
  num_proposta_reversale character varying(7),
  nome_cognome character varying(140),
  indirizzo character varying(30),
  cap character varying(5),
  localita character varying(30),
  provincia character varying(2),
  partita_iva character varying(11),
  codice_fiscale character varying(16),
  causale character varying(370),
  num_pagamento_funzionario_delegato character varying(7),
  progressivo_pagamento_funzionario_delegato character varying(7),
  codice_ente_beneficiario character varying(7),
  descrizione character varying(30),
  id bigserial NOT NULL,
  ente_proprietario_id smallint,
  cro character varying(12),
  CONSTRAINT mif_t_emfe_rr_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE mif_t_emfe_rr
  OWNER TO siac;

