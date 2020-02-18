/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_rep_mptm_up_cap_importi (
  missione_tipo_desc VARCHAR(500),
  missione_code VARCHAR(200),
  missione_desc VARCHAR(500),
  programma_tipo_desc VARCHAR(500),
  programma_code VARCHAR(200),
  programma_desc VARCHAR(500),
  titusc_tipo_desc VARCHAR(500),
  titusc_code VARCHAR(200),
  titusc_desc VARCHAR(500),
  macroag_tipo_desc VARCHAR(500),
  macroag_code VARCHAR(200),
  macroag_desc VARCHAR(500),
  bil_anno VARCHAR(4),
  elem_code VARCHAR(200),
  elem_code2 VARCHAR(200),
  elem_code3 VARCHAR(200),
  elem_desc VARCHAR,
  elem_desc2 VARCHAR,
  elem_id INTEGER,
  elem_id_padre INTEGER,
  stanziamento_prev_anno NUMERIC,
  stanziamento_prev_anno1 NUMERIC,
  stanziamento_prev_anno2 NUMERIC,
  stanziamento_prev_res_anno NUMERIC,
  stanziamento_anno_prec NUMERIC,
  stanziamento_prev_cassa_anno NUMERIC,
  ente_proprietario_id INTEGER,
  utente VARCHAR,
  elem_id_old INTEGER,
  codice_pdc VARCHAR,
  stanziamento_fpv_anno_prec NUMERIC,
  stanziamento_fpv_anno NUMERIC,
  stanziamento_fpv_anno1 NUMERIC,
  stanziamento_fpv_anno2 NUMERIC
) 
WITH (oids = false);