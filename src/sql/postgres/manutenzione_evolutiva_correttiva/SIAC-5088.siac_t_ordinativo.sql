/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
ALTER TABLE siac_t_ordinativo
	ADD COLUMN caus_id INTEGER;

ALTER TABLE siac_t_ordinativo
	ADD CONSTRAINT siac_d_causale_siac_t_ordinativo
	FOREIGN KEY (caus_id) REFERENCES siac_d_causale (caus_id) 
	ON UPDATE NO ACTION ON DELETE NO ACTION;
	
