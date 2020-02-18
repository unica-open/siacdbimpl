/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_rep_gest_equi_bil_imp (
  ente_proprietario_id INTEGER,
  anno VARCHAR(4),
  titolo VARCHAR(200),
  cap_entrata_spesa VARCHAR(200),
  tipo_capitolo VARCHAR(200),
  codice_importo VARCHAR(200),
  pdc_fin VARCHAR(200),
  importo NUMERIC,
  utente VARCHAR
) 
WITH (oids = false);