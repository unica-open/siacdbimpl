/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.tracciato_770_quadro_f_temp (
  f_temp_id SERIAL,
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
  comune_domicilio_fiscale VARCHAR,
  provincia_domicilio_fiscale VARCHAR,
  indirizzo_domicilio_fiscale VARCHAR,
  cap_domicilio_spedizione VARCHAR,
  codice_identif_fiscale_estero VARCHAR,
  causale VARCHAR,
  ammontare_lordo_corrisposto NUMERIC,
  altre_somme_no_ritenute NUMERIC,
  aliquota NUMERIC,
  ritenute_operate NUMERIC,
  ritenute_sospese NUMERIC,
  rimborsi NUMERIC,
  anno_competenza VARCHAR,
  codice_tributo VARCHAR,
  CONSTRAINT tracciato_770_quadro_f_temp_pkey PRIMARY KEY(f_temp_id)
) 
WITH (oids = false);

CREATE UNIQUE INDEX tracciato_770_quadro_f_temp_idx ON siac.tracciato_770_quadro_f_temp
  USING btree (elab_id_temp, elab_id_det_temp);