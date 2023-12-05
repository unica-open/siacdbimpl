/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_rep_titolo_missione (
  ente_proprietario_id INTEGER NOT NULL,
  titolo VARCHAR(200) NOT NULL,
  missione VARCHAR(200) NOT NULL,
  classif_id_titolo INTEGER,
  classif_id_missione INTEGER,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200)
) 
WITH (oids = false);