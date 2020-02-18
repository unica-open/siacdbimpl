/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_rep_var_spese_riga (
  elem_id INTEGER,
  variazione_aumento_stanziato NUMERIC,
  variazione_diminuzione_stanziato NUMERIC,
  variazione_aumento_cassa NUMERIC,
  variazione_diminuzione_cassa NUMERIC,
  variazione_aumento_residuo NUMERIC,
  variazione_diminuzione_residuo NUMERIC,
  utente VARCHAR,
  ente_proprietario INTEGER,
  periodo_anno VARCHAR(4)
) 
WITH (oids = false);