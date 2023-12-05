/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
INSERT INTO siac.siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id, login_operazione)
select tmp.az_code, tmp.az_desc, ta.azione_tipo_id, ga.gruppo_azioni_id, tmp.az_url, to_timestamp('01/01/2017','dd/mm/yyyy'), e.ente_proprietario_id, 'admin'
from siac_d_azione_tipo ta
join siac_t_ente_proprietario e on (ta.ente_proprietario_id = e.ente_proprietario_id)
join siac_d_gruppo_azioni ga on (ga.ente_proprietario_id = e.ente_proprietario_id)
join (values
	('OP-GESC088-ricercaAnagraficaComponenti', 'Ricerca Anagrafica Componenti', 'ATTIVITA_SINGOLA', 'BIL_ALTRO', '/../siacbilapp/azioneRichiesta.do'),
	('OP-GESC089-inserisiciAnagraficaComponenti', 'Inserisci Anagrafica Componenti', 'ATTIVITA_SINGOLA', 'BIL_ALTRO', '/../siacbilapp/azioneRichiesta.do')
) as tmp (az_code, az_desc, az_tipo, az_gruppo, az_url) on (tmp.az_tipo = ta.azione_tipo_code and tmp.az_gruppo = ga.gruppo_azioni_code)
where not exists (
	select 1
	from siac_t_azione z
	where z.azione_tipo_id = ta.azione_tipo_id
	and z.azione_code = tmp.az_code
);
