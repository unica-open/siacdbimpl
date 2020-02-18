/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.tracciato_770_quadro_c_temp (
  c_temp_id SERIAL,
  elab_id_temp INTEGER NOT NULL,
  elab_id_det_temp INTEGER NOT NULL,
  ente_proprietario_id INTEGER,
  tipo_record VARCHAR,
  codice_fiscale_ente VARCHAR,
  codice_fiscale_percipiente VARCHAR,
  tipo_percipiente VARCHAR,
  cognome_denominazione VARCHAR,
  nome VARCHAR,
  sesso VARCHAR,
  data_nascita TIMESTAMP WITHOUT TIME ZONE,
  comune_nascita VARCHAR,
  provincia_nascita VARCHAR,
  comune_domicilio_spedizione VARCHAR,
  provincia_domicilio_spedizione VARCHAR,
  indirizzo_domicilio_spedizione VARCHAR,
  cap_domicilio_spedizione VARCHAR,
  percipienti_esteri_cod_fiscale VARCHAR,
  causale VARCHAR,
  ammontare_lordo_corrisposto NUMERIC,
  altre_somme_no_ritenute NUMERIC,
  imponibile_b NUMERIC,
  ritenute_titolo_acconto_b NUMERIC,
  ritenute_titolo_imposta_b NUMERIC,
  contr_prev_carico_sog_erogante NUMERIC,
  contr_prev_carico_sog_percipie NUMERIC,
  codice VARCHAR,
  anno_competenza VARCHAR,
  codice_tributo VARCHAR,
  CONSTRAINT tracciato_770_quadro_c_temp_pkey PRIMARY KEY(c_temp_id)
) 
WITH (oids = false);

CREATE UNIQUE INDEX tracciato_770_quadro_c_temp_idx ON siac.tracciato_770_quadro_c_temp
  USING btree (elab_id_temp, elab_id_det_temp);