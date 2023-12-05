/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_rep_soggetto_fisico_sedi (
  soggetto_id INTEGER,
  tipo_sede VARCHAR,
  via VARCHAR,
  toponimo VARCHAR,
  numero_civico VARCHAR,
  interno VARCHAR,
  frazione VARCHAR,
  comune VARCHAR,
  provincia_desc_sede VARCHAR,
  provincia_sigla VARCHAR,
  stato_sede VARCHAR,
  avviso VARCHAR,
  ente_proprietario INTEGER,
  utente VARCHAR
) 
WITH (oids = false);