/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/



create table if not exists siac_s_azione_richiesta
as select azione_richiesta_id::int4,
attivita_id,
da_cruscotto,
data,
azione_id,
account_id,
ente_proprietario_id,
validita_inizio,
validita_fine,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione
from siac_t_azione_richiesta 
where data_creazione < '2023-01-01';


create table if not exists siac_s_parametro_azione_richiesta
as select parametro_id::int4,
azione_richiesta_id,
nome,
valore,
ente_proprietario_id,
validita_inizio,
validita_fine,
data_creazione,
data_modifica,
data_cancellazione,
login_operazione
from siac_t_parametro_azione_richiesta 
where data_creazione < '2023-01-01';


delete from siac_t_parametro_azione_richiesta 
	where data_creazione < '2023-01-01';

delete from siac_t_azione_richiesta 
where data_creazione < '2023-01-01';