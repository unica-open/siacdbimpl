/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

--- 31.10.2022 Sofia 
--  trattamento dati per svecchiamenti 2021
--  SIAC-8161_TD_x_svecchiamento_2021_31102022.sql
-- eseguito in prod il 04.11.2022

select distinct   stato.file_pagopa_stato_code
from siac_t_file_pagopa file,siac_d_file_pagopa_stato stato
where stato.ente_proprietario_id=2
and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
and   file.file_pagopa_anno::integer=2021
order by file.data_creazione desc
--ANNULLATO
--ELABORATO_IN_CORSO_ER
--ELABORATO_OK
--RIFIUTATO

-- ANNULLATI
select 
file.file_pagopa_id , file.file_pagopa_id_flusso , file.data_creazione , file.data_modifica , file.data_cancellazione , file.validita_fine , coalesce(file.validita_fine, file.data_modifica, file.validita_fine),
 file.login_operazione 
from siac_t_file_pagopa file,siac_d_file_pagopa_stato stato
where stato.ente_proprietario_id=2
and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
and   file.file_pagopa_anno::integer=2021
and    stato.file_pagopa_stato_code ='ANNULLATO'
order by file.data_creazione desc


-- eseguito in prod 
update siac_t_file_pagopa file
set    validita_fine=coalesce(file.validita_fine,file.data_modifica,file.validita_fine),
         data_cancellazione=coalesce(file.data_cancellazione, file.data_modifica, file.data_cancellazione),
         login_operazione =file.login_operazione||'-SIAC-8161'
from siac_d_file_pagopa_stato stato
where stato.ente_proprietario_id=2
and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
and   file.file_pagopa_anno::integer=2021
and    stato.file_pagopa_stato_code ='ANNULLATO'


select 
count(*)
from siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_t_riconciliazione  ric,pagopa_t_riconciliazione_doc doc 
where stato.ente_proprietario_id=2
and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
and   file.file_pagopa_anno::integer=2021
--and    stato.file_pagopa_stato_code ='ANNULLATO'
and    stato.file_pagopa_stato_code ='RIFIUTATO'
and   ric.file_pagopa_id =file.file_pagopa_id 
and   doc.pagopa_ric_id=ric.pagopa_ric_id



select 
file.file_pagopa_id , file.file_pagopa_id_flusso , file.data_creazione , file.data_modifica , file.data_cancellazione , file.validita_fine , coalesce(file.validita_fine, file.data_modifica, file.validita_fine)
from siac_t_file_pagopa file,siac_d_file_pagopa_stato stato
where stato.ente_proprietario_id=2
and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
and   file.file_pagopa_anno::integer=2021
and    stato.file_pagopa_stato_code ='RIFIUTATO'
order by file.data_creazione desc

select --stato.file_pagopa_stato_code,file.file_pagopa_id,
distinct
       file.file_pagopa_id,
       file.file_pagopa_id_flusso,
       file.data_Creazione,
       er.pagopa_ric_errore_desc,
       ric.pagopa_ric_flusso_anno_accertamento,
	   ric.pagopa_ric_flusso_num_accertamento,
       ric.pagopa_ric_flusso_anno_provvisorio,
	   ric.pagopa_ric_flusso_num_provvisorio,
       ric.pagopa_ric_flusso_voce_code,
       ric.pagopa_ric_flusso_voce_desc,
       ric.pagopa_ric_flusso_sottovoce_code
from siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,
     pagopa_t_riconciliazione ric left join pagopa_d_riconciliazione_errore er on ( er.pagopa_ric_errore_id=ric.pagopa_ric_errore_id)
where stato.ente_proprietario_id=2
and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
and   file.file_pagopa_anno::integer=2021
and   stato.file_pagopa_stato_code not in ('ELABORATO_OK','ANNULLATO','RIFIUTATO')
--and   er.pagopa_ric_errore_desc!='DATI DI RICONCILIAZIONE ASSOCIATI A ACCERTAMENTO NON ESISTENTE'
and    er.pagopa_ric_errore_desc is not null -- solo righe in errore
and   ric.file_pagopa_id=file.file_pagopa_id
order by file.data_creazione desc,
         ric.pagopa_ric_flusso_anno_accertamento,
	     ric.pagopa_ric_flusso_num_accertamento,
         ric.pagopa_ric_flusso_anno_provvisorio,
	     ric.pagopa_ric_flusso_num_provvisorio
-- 2021-12-24SIGPITM1XXX-S012100527

 --- non dovrebbe essere cancellato con la cancellazione del 2021
select  file.file_pagopa_id_flusso , file.data_modifica ,file.data_cancellazione , file.validita_fine ,stato.file_pagopa_stato_code 
from siac_t_file_pagopa file, siac_d_file_pagopa_stato  stato 
where stato.ente_proprietario_id =2
and     stato.file_pagopa_stato_id=file.file_pagopa_stato_id 
and     file.file_pagopa_id_flusso ='2021-12-24SIGPITM1XXX-S012100527'

select  file.file_pagopa_id_flusso , file.data_creazione ,file.data_modifica ,file.data_cancellazione , file.validita_fine ,stato.file_pagopa_stato_code ,
             elab.pagopa_elab_data 
from siac_t_file_pagopa file, siac_d_file_pagopa_stato  stato ,pagopa_r_elaborazione_file  r,pagopa_t_elaborazione  elab 
where stato.ente_proprietario_id =2
and     stato.file_pagopa_stato_id=file.file_pagopa_stato_id 
and     file.file_pagopa_id_flusso ='2021-12-24SIGPITM1XXX-S012100527'
and    r.file_pagopa_id =file.file_pagopa_id 
and    elab.pagopa_elab_id =r.pagopa_elab_id 
order by elab.pagopa_elab_data desc 

-- rimesso IN_CORSO_ER
update siac_t_file_pagopa  file 
set         file_pagopa_stato_id=stato.file_pagopa_stato_id ,
              data_cancellazione=null,
              validita_fine=null,
              data_modifica=now()--,
--              login_operazione =file.login_operazione ||'-SIAC-8161'
from siac_d_file_pagopa_stato  stato 
where stato.ente_proprietario_id =2
and     stato.file_pagopa_stato_code ='ELABORATO_IN_CORSO_ER'
and     file.ente_proprietario_id =2
and     file.file_pagopa_id_flusso ='2021-12-24SIGPITM1XXX-S012100527'

	     