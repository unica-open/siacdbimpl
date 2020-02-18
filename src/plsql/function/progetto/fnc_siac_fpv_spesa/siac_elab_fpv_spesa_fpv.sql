/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_elab_fpv_spesa_fpv (
  programma_id INTEGER,
  anno_bilancio VARCHAR,
  anno VARCHAR,
  importo_fpv NUMERIC,
  elem_id INTEGER,
  movgest_id_imp INTEGER,
  movgest_code_imp VARCHAR,
  movgest_desc_imp VARCHAR,
  movgest_anno_imp VARCHAR,
  movgest_ts_id_imp INTEGER,
  movgest_ts_code_imp VARCHAR,
  movgest_id_acc INTEGER,
  movgest_code_acc VARCHAR,
  movgest_desc_acc VARCHAR,
  movgest_anno_acc VARCHAR,
  movgest_ts_id_acc INTEGER,
  movgest_ts_code_acc VARCHAR,
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