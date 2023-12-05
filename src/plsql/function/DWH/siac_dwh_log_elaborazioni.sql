/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_dwh_log_elaborazioni (
  log_id SERIAL,
  ente_proprietario_id INTEGER,
  fnc_name VARCHAR,
  fnc_parameters VARCHAR,
  fnc_elaborazione_inizio TIMESTAMP WITHOUT TIME ZONE,
  fnc_elaborazione_fine TIMESTAMP WITHOUT TIME ZONE,
  fnc_user VARCHAR,
  fnc_durata INTERVAL(0)
) 
WITH (oids = false);
