/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_rep_cap_uscita_completo (
  programma_id INTEGER,
  macroaggregato_id INTEGER,
  bil_anno VARCHAR(4),
  elem_id INTEGER,
  elem_code VARCHAR(200),
  elem_code2 VARCHAR(200),
  elem_code3 VARCHAR(200),
  elem_desc VARCHAR,
  elem_desc2 VARCHAR,
  elem_id_padre INTEGER,
  elem_tipo_id INTEGER,
  bil_id INTEGER,
  ordine VARCHAR(200),
  livello INTEGER,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER,
  data_creazione TIMESTAMP WITHOUT TIME ZONE,
  data_modifica TIMESTAMP WITHOUT TIME ZONE,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200),
  codice_pdc VARCHAR,
  utente VARCHAR,
  tipo_capitolo VARCHAR
) 
WITH (oids = false);