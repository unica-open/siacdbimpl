/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_rep_ep_imp_ricorrenti_riga (
  elem_id INTEGER,
  entrata_ricorrente_anno NUMERIC,
  entrata_ricorrente_anno1 NUMERIC,
  entrata_ricorrente_anno2 NUMERIC,
  ente_proprietario_id INTEGER,
  utente VARCHAR
) 
WITH (oids = false);