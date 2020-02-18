/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_rep_cap_up_imp_riga (
  elem_id INTEGER,
  stanziamento_prev_anno NUMERIC,
  stanziamento_prev_anno1 NUMERIC,
  stanziamento_prev_anno2 NUMERIC,
  stanziamento_prev_res_anno NUMERIC,
  stanziamento_anno_prec NUMERIC,
  stanziamento_prev_cassa_anno NUMERIC,
  stanziamento_fpv_anno_prec NUMERIC,
  stanziamento_fpv_anno NUMERIC,
  stanziamento_fpv_anno1 NUMERIC,
  stanziamento_fpv_anno2 NUMERIC,
  ente_proprietario_id INTEGER,
  utente VARCHAR
) 
WITH (oids = false);