/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.bko_t_report_importi_anno_bil (
  rep_codice VARCHAR(200),
  rep_desc VARCHAR(500),
  repimp_codice VARCHAR(200),
  repimp_desc VARCHAR(500),
  repimp_importo INTEGER,
  repimp_modificabile CHAR(1),
  repimp_progr_riga INTEGER,
  anno_bil VARCHAR(4)
  CONSTRAINT bko_t_report_importi_chk CHECK (repimp_modificabile = ANY (ARRAY['S'::bpchar, 'N'::bpchar]))
) 
WITH (oids = false);

CREATE TABLE siac.bko_t_report_competenze_anno_bil (
  rep_codice VARCHAR(200),
  rep_competenza_anni INTEGER,
  anno_bil VARCHAR(4)
) 
WITH (oids = false);

CREATE TABLE siac.siac_t_report_importi_appo (
  repimp_id INTEGER,
  repimp_codice VARCHAR(200),
  repimp_desc VARCHAR(500),
  repimp_importo NUMERIC,
  repimp_modificabile CHAR(1),
  repimp_progr_riga INTEGER,
  bil_id INTEGER,
  periodo_id INTEGER,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER,
  data_creazione TIMESTAMP WITHOUT TIME ZONE,
  data_modifica TIMESTAMP WITHOUT TIME ZONE,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200)
) 
WITH (oids = false);

CREATE TABLE siac.siac_r_report_importi_appo (
  reprimp_id INTEGER,
  rep_id INTEGER,
  repimp_id INTEGER,
  posizione_stampa INTEGER,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER,
  data_creazione TIMESTAMP WITHOUT TIME ZONE,
  data_modifica TIMESTAMP WITHOUT TIME ZONE,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200)
) 
WITH (oids = false);