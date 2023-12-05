 /*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/	

CREATE TABLE IF NOT EXISTS siac.sirfel_t_dati_ritenuta (
  id_ritenuta SERIAL, 
  ente_proprietario_id INTEGER NOT NULL,
  id_fattura INTEGER NOT NULL,
  tipo VARCHAR(4) NOT NULL,
  importo NUMERIC(15,2) NOT NULL,
  aliquota NUMERIC(6,2) NOT NULL,
  causale_pagamento VARCHAR(4),
  validita_inizio timestamp without time zone NOT NULL,
  validita_fine timestamp without time zone,
  data_creazione timestamp without time zone NOT NULL DEFAULT now(),
  data_modifica timestamp without time zone NOT NULL DEFAULT now(),
  data_cancellazione timestamp without time zone,
  login_operazione character varying(200),
  CONSTRAINT pk_sirfel_t_dati_ritenuta PRIMARY KEY (id_ritenuta),
  CONSTRAINT sirfel_t_dati_ritenuta_fk1 FOREIGN KEY (id_fattura, ente_proprietario_id)
  REFERENCES siac.sirfel_t_fattura(id_fattura, ente_proprietario_id)
) 

/*CREATE SEQUENCE IF NOT EXISTS siac.sirfel_t_dati_ritenuta_num_id_seq
  INCREMENT 1 MINVALUE 1
  MAXVALUE 9223372036854775807 START 1
  CACHE 1;*/

ALTER SEQUENCE siac.sirfel_t_dati_ritenuta_num_id_seq RESTART WITH 2;
