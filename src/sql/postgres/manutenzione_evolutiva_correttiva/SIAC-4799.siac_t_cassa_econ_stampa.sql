/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
ALTER TABLE siac_t_cassa_econ_stampa
	ADD COLUMN attoal_id INTEGER;

ALTER TABLE siac_t_cassa_econ_stampa
	ADD CONSTRAINT siac_t_atto_allegato_siac_t_cassa_econ_stampa
	FOREIGN KEY (attoal_id) REFERENCES siac_t_atto_allegato (attoal_id) 
	ON UPDATE NO ACTION ON DELETE NO ACTION;