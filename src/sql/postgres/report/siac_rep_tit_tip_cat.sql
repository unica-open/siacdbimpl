/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_rep_tit_tip_cat (
  classif_classif_fam_tree_id INTEGER,
  classif_fam_tree_id INTEGER,
  classif_code VARCHAR(200),
  classif_desc VARCHAR(500),
  classif_tipo_desc VARCHAR(500),
  classif_id INTEGER,
  classif_id_padre INTEGER,
  ente_proprietario_id INTEGER,
  ordine VARCHAR(200),
  level INTEGER,
  utente VARCHAR
) 
WITH (oids = false);