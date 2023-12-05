/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
create table if not exists siac.siac_t_config_rep_ce_sp_gsa (
voce_id SERIAL,
tipo_report VARCHAR(2) NOT NULL,
cod_voce  VARCHAR(200) NOT NULL,
segno INTEGER NOT NULL,
titolo varchar(1) NOT NULL,
bil_id INTEGER NOT NULL,
validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
validita_fine TIMESTAMP WITHOUT TIME ZONE,
ente_proprietario_id INTEGER NOT NULL,
data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
login_operazione VARCHAR(200) NOT NULL,
CONSTRAINT pk_siac_t_config_rep_ce_sp_gsa PRIMARY KEY(voce_id),
CONSTRAINT siac_t_ente_proprietario_siac_t_config_rep_ce_sp_gsa FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE)
WITH (oids = false);
