/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


DROP TABLE if exists siac.siac_gsa_ordinativi_log_elab;

CREATE TABLE siac.siac_gsa_ordinativi_log_elab (
	log_id serial4 NOT NULL,
	ente_proprietario_id int4 NULL,
	fnc_name varchar NULL,
	fnc_parameters varchar NULL,
	fnc_elaborazione_inizio timestamp NULL,
	fnc_elaborazione_fine timestamp NULL,
	fnc_user varchar NULL,
	fnc_durata interval NULL
);