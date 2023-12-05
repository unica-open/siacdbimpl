/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/	

insert into siac.sirfel_d_modalita_pagamento(ente_proprietario_id, codice, descrizione)
	select ente.ente_proprietario_id, 'MP23', 'PagoPA'
	from siac.siac_t_ente_proprietario ente
	where NOT EXISTS (
		SELECT 1 FROM siac.sirfel_d_modalita_pagamento z WHERE z.codice = 'MP23' AND z.ente_proprietario_id = ente.ente_proprietario_id);
		
