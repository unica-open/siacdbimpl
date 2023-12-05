/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_elab_fpv_spesa_imp (
  programma_id INTEGER,
  anno_bilancio VARCHAR,
  anno VARCHAR,
  elem_id INTEGER,
  movgest_id INTEGER,
  movgest_anno VARCHAR,
  movgest_desc VARCHAR,
  movgest_ts_id INTEGER,
  movgest_ts_code VARCHAR,
  importo_impegno NUMERIC,
  classif_id_missione INTEGER,
  classif_code_missione VARCHAR,
  classif_desc_missione VARCHAR,
  classif_tipo_code_missione VARCHAR,
  classif_id_programma INTEGER,
  classif_code_programma VARCHAR,
  classif_desc_programma VARCHAR,
  classif_tipo_code_programma VARCHAR,
  classif_id_titolo INTEGER,
  classif_code_titolo VARCHAR,
  classif_desc_titolo VARCHAR,
  classif_tipo_code_titolo VARCHAR,
  user_code VARCHAR
) 