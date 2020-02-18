/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_t_subdoc_sospensione (
	subdoc_sosp_id                 SERIAL NOT NULL,
	subdoc_sosp_data               TIMESTAMP WITHOUT TIME ZONE NOT NULL,
	subdoc_sosp_causale            VARCHAR(200) NOT NULL,
	subdoc_sosp_data_riattivazione TIMESTAMP WITHOUT TIME ZONE,
	subdoc_id                      INTEGER NOT NULL,
	validita_inizio                TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    validita_fine                  TIMESTAMP WITHOUT TIME ZONE,
    ente_proprietario_id           INTEGER  NOT NULL,
    data_creazione                 TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_modifica                  TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_cancellazione             TIMESTAMP WITHOUT TIME ZONE,
    login_operazione               CHARACTER VARYING(200) NOT NULL,
	CONSTRAINT PK_siac_t_subdoc_sospensione PRIMARY KEY (subdoc_sosp_id),
	CONSTRAINT siac_t_ente_proprietario_siac_t_subdoc_sospensione FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION,
	CONSTRAINT siac_t_subdoc_siac_t_subdoc_sospensione FOREIGN KEY (subdoc_id)
		REFERENCES siac.siac_t_subdoc(subdoc_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
);
