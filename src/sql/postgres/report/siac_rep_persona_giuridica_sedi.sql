/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_rep_persona_giuridica_sedi (
  soggetto_id INTEGER,
  via_sede VARCHAR,
  toponimo_sede VARCHAR,
  numero_civico_sede VARCHAR,
  interno_sede VARCHAR,
  frazione_sede VARCHAR,
  comune_sede VARCHAR,
  provincia_desc_sede VARCHAR,
  provincia_sigla_sede VARCHAR,
  stato_sede VARCHAR,
  avviso_sede VARCHAR,
  indirizzo_id_sede INTEGER,
  ente_proprietario INTEGER,
  utente VARCHAR
) 
WITH (oids = false);