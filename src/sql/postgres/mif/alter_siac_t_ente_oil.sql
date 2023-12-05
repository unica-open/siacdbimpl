/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
ter table siac_t_ente_oil add  ente_oil_quiet_ord  boolean default false not null


update siac_t_ente_oil set ente_oil_quiet_ord=true
where ente_proprietario_id in (2,4,5,10,11,13)

select e.ente_proprietario_id, e.ente_denominazione , oil.ente_oil_quiet_ord
from siac_t_ente_oil oil, siac_t_ente_proprietario e
where e.ente_proprietario_id=oil.ente_proprietario_id
order by e.ente_proprietario_id;





