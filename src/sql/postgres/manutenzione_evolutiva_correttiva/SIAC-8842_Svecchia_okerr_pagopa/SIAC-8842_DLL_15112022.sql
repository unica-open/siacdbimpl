/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

select *
from pagopa_d_elaborazione_svecchia_tipo tipo

insert into pagopa_d_elaborazione_svecchia_tipo
(
    pagopa_elab_svecchia_tipo_code,
	pagopa_elab_svecchia_tipo_desc,
	pagopa_elab_svecchia_tipo_fl_attivo,
	pagopa_elab_svecchia_tipo_fl_back,
	pagopa_elab_svecchia_delta_giorni,	
	validita_inizio,
	ente_proprietario_id,
	login_operazione
)
select 'PUNTUALE-OK',
	        'SVECCHIAMENTO PUNTUALE ELAB. IN ERRORE PER FLUSSI OK',
	        true,
	        true,
	        6,
	        now(),
	        ente.ente_proprietario_id ,
	        'SIAC-8442'
from siac_t_ente_proprietario ente 
where ente.ente_proprietario_id =2

select date_trunc('DAY',now()-interval '0 months')
select date_trunc('DAY',now()+interval '1 days')