/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_rep_up_imp_ricorrenti_riga (
  elem_id INTEGER,
  spesa_ricorrente_anno NUMERIC,
  spesa_ricorrente_anno1 NUMERIC,
  spesa_ricorrente_anno2 NUMERIC,
  ente_proprietario_id INTEGER,
  utente VARCHAR
) 
WITH (oids = false);