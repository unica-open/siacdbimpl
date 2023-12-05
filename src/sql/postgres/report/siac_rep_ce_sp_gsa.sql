/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE if not exists siac.siac_rep_ce_sp_gsa (
  classif_id INTEGER,
  cod_voce VARCHAR,
  descrizione_voce VARCHAR,
  livello_codifica INTEGER,
  padre VARCHAR,
  foglia VARCHAR,
  classif_tipo_code VARCHAR(200),
  pdce_conto_code VARCHAR,
  pdce_conto_descr VARCHAR,
  pdce_conto_numerico VARCHAR,
  pdce_fam_code VARCHAR,
  imp_dare NUMERIC,
  imp_avere NUMERIC,
  imp_saldo NUMERIC,
  ente_proprietario_id INTEGER,
  utente VARCHAR
) 
WITH (oids = false);