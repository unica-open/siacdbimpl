/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop view if exists siac.siac_v_dwh_mutuo_ripartizione;

--DROP TABLE if exists siac.siac_d_mutuo_ripartizione_tipo CASCADE;
CREATE TABLE if not exists siac.siac_d_mutuo_ripartizione_tipo (
	mutuo_ripartizione_tipo_id serial NOT NULL,
	mutuo_ripartizione_tipo_code varchar(200) NOT NULL,
	mutuo_ripartizione_tipo_desc varchar(500) NULL,
	--
	ente_proprietario_id integer NOT NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	CONSTRAINT pk_siac_d_mutuo_ripartizione_tipo PRIMARY KEY (mutuo_ripartizione_tipo_id),
	CONSTRAINT siac_t_ente_proprietario_siac_d_mutuo_ripartizione_tipo
		FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
);




--DROP TABLE if exists siac.siac_r_mutuo_ripartizione CASCADE;
CREATE TABLE if not exists siac.siac_r_mutuo_ripartizione (
	mutuo_ripartizione_id serial NOT NULL,
	mutuo_id integer NOT NULL,
	mutuo_ripartizione_tipo_id integer NOT NULL,
	elem_id integer not null,
	mutuo_ripartizione_importo numeric NULL,
	mutuo_ripartizione_perc numeric NULL,
	--
	ente_proprietario_id integer NOT NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	login_creazione varchar(200) NOT NULL,
	login_modifica varchar(200) NOT NULL,
	login_cancellazione varchar(200) NULL,
	CONSTRAINT pk_siac_r_mutuo_ripartizione PRIMARY KEY (mutuo_ripartizione_id),
	CONSTRAINT siac_t_ente_proprietario_siac_r_mutuo_ripartizione 
		FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id),
	CONSTRAINT siac_t_mutuo_siac_r_mutuo_ripartizione  
		FOREIGN KEY (mutuo_id) REFERENCES siac.siac_t_mutuo(mutuo_id),
	CONSTRAINT siac_t_bil_elem_siac_r_mutuo_ripartizione
		FOREIGN KEY (elem_id) REFERENCES siac.siac_t_bil_elem(elem_id)
);


