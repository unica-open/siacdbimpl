/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
ALTER TABLE siac.siac_d_causale ADD COLUMN dist_id INTEGER;

ALTER TABLE siac_d_causale 	ADD CONSTRAINT siac_d_causale_siac_d_distinta FOREIGN KEY (dist_id) REFERENCES siac.siac_d_distinta (dist_id) 
	ON UPDATE NO ACTION ON DELETE NO ACTION;