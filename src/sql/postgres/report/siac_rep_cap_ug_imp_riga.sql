/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_rep_cap_ug_imp_riga (
  elem_id INTEGER,
  residui_passivi NUMERIC,
  previsioni_definitive_comp NUMERIC,
  previsioni_definitive_cassa NUMERIC,
  ente_proprietario_id INTEGER,
  utente VARCHAR,
  periodo_anno VARCHAR(4)
) 
WITH (oids = false);