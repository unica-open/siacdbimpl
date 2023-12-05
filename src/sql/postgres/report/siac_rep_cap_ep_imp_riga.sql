/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_rep_cap_ep_imp_riga (
  elem_id INTEGER,
  stanziamento_prev_anno NUMERIC,
  stanziamento_prev_anno1 NUMERIC,
  stanziamento_prev_anno2 NUMERIC,
  residui_presunti NUMERIC,
  previsioni_anno_prec NUMERIC,
  stanziamento_prev_cassa_anno NUMERIC,
  ente_proprietario_id INTEGER,
  utente VARCHAR
) 
WITH (oids = false);