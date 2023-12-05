/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code, 
 pagopa_ric_errore_desc, 
 validita_inizio, 
 login_operazione,
 ente_proprietario_id
	
)
select '52',
       'DATI DI RICONCILIAZIONE ASSOCIATI A PROVVISORIO DI CASSA ANNULLATO O CON DATA DI REGOLARIZZAZIONE',
       now(),
       'SIAC-8221',
       ente.ente_proprietario_id
from siac_t_ente_proprietario ente 
where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
and   not exists
(
select 1
from pagopa_d_riconciliazione_errore err 
where err.ente_proprietario_id=ente.ente_proprietario_id
and   err.pagopa_ric_errore_code='52'
and   err.data_cancellazione is null 
);



update pagopa_d_riconciliazione_errore err 
set    pagopa_ric_errore_desc='DATI DI RICONCILIAZIONE ASSOCIATI A ACCERTAMENTO NON ESISTENTE O NON DEFINITIVO',
       data_modifica=now(),
       login_operazione=err.login_operazione||'-SIAC-8221'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
and   err.ente_proprietario_id=ente.ente_proprietario_id
and   err.pagopa_ric_errore_code ='23'
and   err.login_operazione not like '%SIAC-8221';
