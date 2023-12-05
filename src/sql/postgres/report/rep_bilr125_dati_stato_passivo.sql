/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.rep_bilr125_dati_stato_passivo (
  anno VARCHAR(4),
  codice_codifica_albero_passivo VARCHAR(200),
  importo_dare NUMERIC,
  importo_avere NUMERIC,
  importo_passivo NUMERIC,
  utente VARCHAR
) 
WITH (oids = false);