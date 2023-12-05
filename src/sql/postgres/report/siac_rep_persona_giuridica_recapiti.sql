/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_rep_persona_giuridica_recapiti (
  soggetto_id INTEGER,
  tipo_indirizzo VARCHAR,
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
  utente VARCHAR,
  desc_tipo_indirizzo VARCHAR,
  indirizzo_id INTEGER
) 
WITH (oids = false);