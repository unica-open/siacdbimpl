/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.tracciato_770_quadro_f (
  f_id SERIAL,
  elab_id INTEGER NOT NULL,
  elab_id_det INTEGER NOT NULL,
  elab_data TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER,
  tipo_record VARCHAR(2),
  codice_fiscale_ente VARCHAR(16),
  codice_fiscale_percipiente VARCHAR(16),
  tipo_percipiente VARCHAR(1),
  cognome_denominazione VARCHAR(24),
  nome VARCHAR(20),
  sesso VARCHAR(1),
  data_nascita VARCHAR(8),
  comune_nascita VARCHAR(21),
  provincia_nascita VARCHAR(2),
  comune_domicilio_fiscale VARCHAR(21),
  provincia_domicilio_fiscale VARCHAR(2),
  indirizzo_domicilio_fiscale VARCHAR(35),
  colonna_1 VARCHAR(60),
  colonna_2 VARCHAR(21),
  colonna_3 VARCHAR(2),
  colonna_4 VARCHAR(35),
  cap_domicilio_spedizione VARCHAR(5),
  colonna_5 VARCHAR(31),
  codice_stato_estero VARCHAR(3),
  codice_identif_fiscale_estero VARCHAR(20),
  causale VARCHAR(1),
  ammontare_lordo_corrisposto VARCHAR(13),
  somme_no_soggette_ritenuta VARCHAR(13),
  aliquota VARCHAR(5),
  ritenute_operate VARCHAR(13),
  ritenute_sospese VARCHAR(13),
  codice_fiscale_rappr_soc VARCHAR(16),
  cognome_denom_rappr_soc VARCHAR(60),
  nome_rappr_soc VARCHAR(20),
  sesso_rappr_soc VARCHAR(1),
  data_nascita_rappr_soc VARCHAR(8),
  comune_nascita_rappr_soc VARCHAR(21),
  provincia_nascita_rappr_soc VARCHAR(2),
  comune_dom_fiscale_rappr_soc VARCHAR(21),
  provincia_rappr_soc VARCHAR(2),
  indirizzo_rappr_soc VARCHAR(35),
  codice_stato_estero_rappr_soc VARCHAR(3),
  rimborsi VARCHAR(13),
  colonna_6 VARCHAR(315),
  colonna_7 VARCHAR(16),
  colonna_8 VARCHAR(1),
  colonna_9 VARCHAR(2),
  colonna_10 VARCHAR(4),
  colonna_11 VARCHAR(4),
  colonna_12 VARCHAR(4),
  colonna_13 VARCHAR(7),
  colonna_14 VARCHAR(6),
  colonna_15 VARCHAR(4),
  colonna_16 VARCHAR(7),
  colonna_17 VARCHAR(4),
  colonna_18 VARCHAR(9),
  colonna_19 VARCHAR(1),
  colonna_20 VARCHAR(1143),
  colonna_21 VARCHAR(4),
  colonna_22 VARCHAR(4),
  colonna_23 VARCHAR(1818),
  anno_competenza VARCHAR(4),
  ex_ente VARCHAR(4),
  progressivo VARCHAR(7),
  matricola VARCHAR(7),
  codice_tributo VARCHAR(4),
  versione_tracciato_procsi VARCHAR(3),
  colonna_28 VARCHAR(9),
  caratteri_controllo_1 VARCHAR(1),
  caratteri_controllo_2 VARCHAR(2),
  CONSTRAINT tracciato_770_quadro_f_pkey PRIMARY KEY(f_id)
) 
WITH (oids = false);

CREATE UNIQUE INDEX tracciato_770_quadro_f_idx ON siac.tracciato_770_quadro_f
  USING btree (elab_id, elab_id_det);