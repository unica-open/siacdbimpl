/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_rep_cap_uscita_imp_completo_riga (
  elem_id INTEGER,
  residuo_anno NUMERIC,
  stanziamento_anno NUMERIC,
  cassa_anno NUMERIC,
  residuo_iniz_anno NUMERIC,
  stanziamento_iniz_anno NUMERIC,
  cassa_iniz_anno NUMERIC,
  residuo_anno1 NUMERIC,
  stanziamento_anno1 NUMERIC,
  cassa_anno1 NUMERIC,
  residuo_iniz_anno1 NUMERIC,
  stanziamento_iniz_anno1 NUMERIC,
  cassa_iniz_anno1 NUMERIC,
  residuo_anno2 NUMERIC,
  stanziamento_anno2 NUMERIC,
  cassa_anno2 NUMERIC,
  residuo_iniz_anno2 NUMERIC,
  stanziamento_iniz_anno2 NUMERIC,
  cassa_iniz_anno2 NUMERIC,
  ente_proprietario_id INTEGER,
  utente VARCHAR
) 
WITH (oids = false);