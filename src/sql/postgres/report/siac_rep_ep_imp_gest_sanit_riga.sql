/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_rep_ep_imp_gest_sanit_riga (
  elem_id INTEGER,
  entrata_gest_sanit_comp_anno NUMERIC,
  entrata_gest_sanit_comp_anno1 NUMERIC,
  entrata_gest_sanit_comp_anno2 NUMERIC,
  entrata_gest_sanit_cassa_anno NUMERIC,
  entrata_gest_sanit_cassa_anno1 NUMERIC,
  entrata_gest_sanit_cassa_anno2 NUMERIC,
  entrata_gest_sanit_resid_anno NUMERIC,
  entrata_gest_sanit_resid_anno1 NUMERIC,
  entrata_gest_sanit_resid_anno2 NUMERIC,
  ente_proprietario_id INTEGER,
  utente VARCHAR
) 
WITH (oids = false);