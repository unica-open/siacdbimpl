/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_rep_raccordo_pdce_bil (
  ente_proprietario_id INTEGER,
  classif_code VARCHAR(200),
  classif_id INTEGER,
  classif_id_padre INTEGER,
  livello INTEGER,
  ordine VARCHAR,
  utente VARCHAR
) 
WITH (oids = false);