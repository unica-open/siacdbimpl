/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_rep_tit_tip_cat_riga (
  classif_tipo_desc1 VARCHAR(500),
  titolo_id INTEGER,
  titolo_code VARCHAR(200),
  titolo_desc VARCHAR(500),
  classif_tipo_desc2 VARCHAR(500),
  tipologia_id INTEGER,
  tipologia_code VARCHAR(200),
  tipologia_desc VARCHAR(500),
  classif_tipo_desc3 VARCHAR(500),
  categoria_id INTEGER,
  categoria_code VARCHAR(200),
  categoria_desc VARCHAR(500),
  ente_proprietario_id INTEGER,
  utente VARCHAR
) 
WITH (oids = false);