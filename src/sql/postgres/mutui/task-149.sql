/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


update siac.siac_d_mutuo_ripartizione_tipo set mutuo_ripartizione_tipo_desc = 'Capitale' where mutuo_ripartizione_tipo_code = '01';
update siac.siac_d_mutuo_ripartizione_tipo set mutuo_ripartizione_tipo_desc = 'Interessi' where mutuo_ripartizione_tipo_code = '02';

ALTER TABLE IF EXISTS siac.siac_r_mutuo_ripartizione DROP CONSTRAINT IF EXISTS siac_d_mutuo_ripartizione_tipo_siac_r_mutuo_ripartizione;
ALTER TABLE siac.siac_r_mutuo_ripartizione 
	ADD CONSTRAINT siac_d_mutuo_ripartizione_tipo_siac_r_mutuo_ripartizione 
	FOREIGN KEY (mutuo_ripartizione_tipo_id) REFERENCES siac.siac_d_mutuo_ripartizione_tipo(mutuo_ripartizione_tipo_id);
