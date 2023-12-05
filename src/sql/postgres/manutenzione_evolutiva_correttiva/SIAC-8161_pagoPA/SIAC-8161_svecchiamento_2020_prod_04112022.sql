/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

-- SIAC-8161_svecchiamento_2020_prod_04112022.sql
-- eseguito in produzione 
select 
 stato.file_pagopa_stato_code,count(*)
from siac_t_file_pagopa file,siac_d_file_pagopa_stato stato
where stato.ente_proprietario_id=2
and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
and   file.file_pagopa_anno::integer=2020
group by  stato.file_pagopa_stato_code
-- ELABORATO_OK	16534
-- ELABORATO_OK	244
select --count(*)
       stato.file_pagopa_stato_code,file.file_pagopa_id,
       file.file_pagopa_id_flusso,
       file.file_pagopa_anno,
       file.data_Creazione,
       file.data_cancellazione , file.validita_fine 
from siac_t_file_pagopa file,siac_d_file_pagopa_stato stato
where stato.ente_proprietario_id=2
and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
and   file.file_pagopa_anno::integer=2020
order by file.data_creazione desc
-- 16.534
-- 244

select 
distinct 
       stato.file_pagopa_stato_code,file.file_pagopa_id,
       file.file_pagopa_id_flusso,
       file.file_pagopa_anno,
       file.data_Creazione,
       file.data_cancellazione , file.validita_fine 
from siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_t_riconciliazione  r
where stato.ente_proprietario_id=2
and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
and   file.file_pagopa_anno::integer=2020
and   r.file_pagopa_id =file.file_pagopa_id 
order by file.data_creazione desc
-- 16.533
-- 243
select 
       stato.file_pagopa_stato_code,count(*) 
from siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_t_riconciliazione  r
where stato.ente_proprietario_id=2
and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
and   file.file_pagopa_anno::integer=2020
and   r.file_pagopa_id =file.file_pagopa_id 
group by stato.file_pagopa_stato_code
-- ELABORATO_OK	19689
-- ELABORATO_OK	303

select count(*) from pagopa_t_riconciliazione_det  det 
-- 7963908

select --count(*)
 stato.file_pagopa_stato_code,count(*) 
from siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_t_riconciliazione  r,pagopa_t_riconciliazione_Det det 
where stato.ente_proprietario_id=2
and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
and   file.file_pagopa_anno::integer=2020
and   r.file_pagopa_id =file.file_pagopa_id 
and   det.pagopa_ric_id=r.pagopa_ric_id
group by stato.file_pagopa_stato_code
-- 1687641
-- ELABORATO_OK	1687641
-- ELABORATO_OK	34260


select --count(*)
 stato.file_pagopa_stato_code,count(*)
from siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_t_riconciliazione  r,pagopa_t_riconciliazione_Doc det 
where stato.ente_proprietario_id=2
and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
and   file.file_pagopa_anno::integer=2020
and   r.file_pagopa_id =file.file_pagopa_id 
and   det.pagopa_ric_id=r.pagopa_ric_id
group by stato.file_pagopa_stato_code
-- 19821
-- ELABORATO_OK	19821
-- ELABORATO_OK	305


select count(*)
-- stato.file_pagopa_stato_code,count(*)
from siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_t_riconciliazione  r,pagopa_t_riconciliazione_Doc det ,pagopa_t_elaborazione_flusso  flusso 
where stato.ente_proprietario_id=2
and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
and   file.file_pagopa_anno::integer=2020
and   r.file_pagopa_id =file.file_pagopa_id 
and   det.pagopa_ric_id=r.pagopa_ric_id
and   flusso.pagopa_elab_flusso_id =det.pagopa_elab_flusso_id  
group by stato.file_pagopa_stato_code
--19821
-- ELABORATO_OK	19821

select distinct elab.pagopa_elab_data , elab.pagopa_elab_id , stato_elab.pagopa_elab_stato_code , stato.file_pagopa_stato_code ,file.file_pagopa_id 
from siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_t_riconciliazione  r,pagopa_t_riconciliazione_Doc det ,pagopa_t_elaborazione_flusso  flusso ,
pagopa_r_elaborazione_file  rfile ,pagopa_t_elaborazione  elab, pagopa_d_elaborazione_stato  stato_elab 
where stato.ente_proprietario_id=2
and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
and   file.file_pagopa_anno::integer=2020
and   r.file_pagopa_id =file.file_pagopa_id 
and   det.pagopa_ric_id=r.pagopa_ric_id
and   flusso.pagopa_elab_flusso_id =det.pagopa_elab_flusso_id  
and   rfile.pagopa_elab_id =flusso.pagopa_elab_id 
and    rfile.file_pagopa_id =file.file_pagopa_id 
and   elab.pagopa_elab_id =rfile.pagopa_elab_id 
and   stato_elab.pagopa_elab_stato_id =elab.pagopa_elab_stato_id 
and   stato_elab.pagopa_elab_stato_code not in ('ELABORATO_OK')
-- 4.905
-- 16.533

-- 243
select --distinct elab.pagopa_elab_data , elab.pagopa_elab_id , stato_elab.pagopa_elab_stato_code , stato.file_pagopa_stato_code ,file.file_pagopa_id 
--stato_elab.pagopa_elab_stato_code,
stato.file_pagopa_stato_code ,count(*)
from siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_t_riconciliazione  r,pagopa_t_riconciliazione_Doc det ,pagopa_t_elaborazione_flusso  flusso ,
pagopa_r_elaborazione_file  rfile ,pagopa_t_elaborazione  elab, pagopa_d_elaborazione_stato  stato_elab 
where stato.ente_proprietario_id=2
and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
and   file.file_pagopa_anno::integer=2020
and   r.file_pagopa_id =file.file_pagopa_id 
and   det.pagopa_ric_id=r.pagopa_ric_id
and   flusso.pagopa_elab_flusso_id =det.pagopa_elab_flusso_id  
and   rfile.pagopa_elab_id =flusso.pagopa_elab_id 
and    rfile.file_pagopa_id =file.file_pagopa_id 
and   elab.pagopa_elab_id =rfile.pagopa_elab_id 
and   stato_elab.pagopa_elab_stato_id =elab.pagopa_elab_stato_id 
--and   stato_elab.pagopa_elab_stato_code not in ('ELABORATO_OK')
group by --stato_elab.pagopa_elab_stato_code, 
stato.file_pagopa_stato_code
-- ELABORATO_OK	19821


select *
from pagopa_d_elaborazione_svecchia_tipo tipo
where tipo.ente_proprietario_id =2

   update pagopa_d_elaborazione_svecchia_tipo tipo
   set     pagopa_elab_svecchia_delta_giorni=672,
--            pagopa_elab_svecchia_tipo_fl_back =true,
           data_modifica=now()--,
   --        login_operazione=tipo.login_operazione||'-SIAC-8161'
   where tipo.ente_proprietario_id=2
   and   tipo.pagopa_elab_svecchia_tipo_code='PERIODICO'
   -- 470
   
     select date_trunc('DAY',now()::timestamp)- ( interval '307 days'); -- 2021
     select date_trunc('DAY',now()::timestamp)- ( interval '672 days'); -- 2020
     select date_trunc('DAY',now()::timestamp)- ( interval '1038 days'); -- 2019
     
     
select 
fnc_pagopa_t_elaborazione_riconc_svecchia_ss
(
2,
'SIAC-8161',
now()::timestamp)     
-- (4083,0,"Elaborazione svecchiamento periodico rinconciliazione PAGOPA per  dataSvecchia=01/01/2021.")

-----
dataSvecchiaSqlQuery=select date_trunc('DAY','2022-11-04 17:31:06.303168'::timestamp)- interval '672 day' 
dataSvecchia=2021-01-01 00:00:00
---------- ELEABORAZIONE IN CORSO --------------
strMessaggio= backup pagopa_t_elaborazione - 
inseriti=304
 
inseriti=372
 
inseriti=0
 
strMessaggio= backup pagopa_t_elaborazione_flusso - 
inseriti=11385
 
inseriti=4905
 
inseriti=0
 
strMessaggio= backup pagopa_t_riconciliazione_doc - 
inseriti=13518
 
inseriti=5998
 
inseriti=0
 
strMessaggio= backup pagopa_r_elaborazione_file - 
inseriti=11385
 
inseriti=4905
 
inseriti=0
 
strMessaggio= backup siac_t_file_pagopa - 
inseriti=16290
 
inseriti=0
 
inseriti=0
 
strMessaggio= backup pagopa_t_riconciliazione - 
inseriti=13437
 
inseriti=5949
 
inseriti=0
 
strMessaggio= backup pagopa_t_riconciliazione_det - 
inseriti=1103841
 
inseriti=549540
 
inseriti=0
 
strMessaggio= backup pagopa_t_elaborazione_log - 
inseriti=28335
 
inseriti=7288
 
inseriti=0
 
---------- INIZIO FASE CANCELLAZIONE --------------
strMessaggio= cancellazione pagopa_bck_t_registrounico_doc - 
cancellati=0
strMessaggio= cancellazione pagopa_bck_t_doc_class - 
cancellati=0
strMessaggio= cancellazione pagopa_bck_t_doc_attr - 
cancellati=0
strMessaggio= cancellazione pagopa_bck_t_doc_sog - 
cancellati=0
strMessaggio= cancellazione pagopa_bck_t_subdoc_num - 
cancellati=0
strMessaggio= cancellazione pagopa_bck_t_doc_stato - 
cancellati=0
strMessaggio= cancellazione pagopa_bck_t_doc - 
cancellati=0
strMessaggio= cancellazione pagopa_bck_t_subdoc_movgest_ts - 
cancellati=0
strMessaggio= cancellazione pagopa_bck_t_subdoc_prov_cassa - 
cancellati=0
strMessaggio= cancellazione pagopa_bck_t_subdoc_atto_amm - 
cancellati=0
strMessaggio= cancellazione pagopa_bck_t_subdoc_attr - 
cancellati=0
strMessaggio= cancellazione pagopa_bck_t_subdoc - 
cancellati=0
strMessaggio= cancellazione pagopa_t_elaborazione_log - 
cancellati=35623
cancellati=0
cancellati=0
strMessaggio= cancellazione pagopa_t_riconciliazione_det - 
cancellati=1103841
cancellati=549540
cancellati=0
strMessaggio= cancellazione pagopa_t_riconciliazione_doc (C)- 
cancellati=13518
cancellati=5998
cancellati=0
strMessaggio= cancellazione pagopa_t_riconciliazione - 
cancellati=13437
cancellati=5949
cancellati=0
strMessaggio= cancellazione pagopa_t_elaborazione_flusso (B) - 
cancellati=11385
cancellati=4905
cancellati=0
strMessaggio= cancellazione pagopa_r_elaborazione_file - 
cancellati=11385
cancellati=4905
strMessaggio= cancellazione pagopa_t_modifica_elab x pagopa_r_elaborazione_file ANNULLATI - 
cancellati=0
strMessaggio= cancellazione pagopa_t_elaborazione x pagopa_r_elaborazione_file ANNULLATI - 
cancellati=0
cancellati=0
strMessaggio= cancellazione siac_t_file_pagopa - 
cancellati=16290
altri_record=0
strMessaggio= cancellazione pagopa_r_elaborazione_file - 
pagopa_r_elaborazione_file cancellati=0
strMessaggio= cancellazione pagopa_t_modifica_elab - 
cancellati=2194
strMessaggio= cancellazione pagopa_t_elaborazione - 
cancellati=304
cancellati=372
countDel=1779646
strMessaggio=Fine fnc_pagopa_t_elaborazione_riconc_svecchia -  cancellati complessivamente 1779646 Chiusura elaborazione [pagopa_t_elaborazione_svecchia].
---------- ELABORAZIONE TERMINATA --------------
Fine fnc_pagopa_t_elaborazione_riconc_svecchia -  cancellati complessivamente 1779646Elaborazione svecchiamento periodico rinconciliazione PAGOPA per  dataSvecchia=01/01/2021.
