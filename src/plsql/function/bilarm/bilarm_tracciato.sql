/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.bilarm_tracciato (
  elab_id INTEGER NOT NULL,
  elab_id_det INTEGER NOT NULL,
  elab_data TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER,
  codice_istituto VARCHAR,
  codice_ente VARCHAR,
  anno_esercizio VARCHAR,
  indicativo_entrate_uscite VARCHAR,
  codifica_bilancio VARCHAR,
  numero_articolo VARCHAR,
  anno_residuo VARCHAR,
  descr_codifica_bilancio_pt1 VARCHAR,
  descr_codifica_bilancio_pt2 VARCHAR,
  colonna_1 VARCHAR,
  colonna_2 VARCHAR,
  codice_meccanografico VARCHAR,
  colonna_3 VARCHAR,
  importo_capitolo VARCHAR,
  importo_cassa VARCHAR,
  colonna_4 VARCHAR,
  colonna_5 VARCHAR,
  colonna_6 VARCHAR,
  importo_impegnato VARCHAR,
  importo_fondo_vincolato VARCHAR,
  colonna_7 VARCHAR,
  colonna_8 VARCHAR,
  colonna_9 VARCHAR,
  colonna_10 VARCHAR,
  colonna_11 VARCHAR,
  colonna_12 VARCHAR,
  colonna_13 VARCHAR,
  colonna_14 VARCHAR,
  colonna_15 VARCHAR,
  colonna_16 VARCHAR,
  CONSTRAINT bilarm_tracciato_pkey PRIMARY KEY(elab_id, elab_id_det)
) 
WITH (oids = false);