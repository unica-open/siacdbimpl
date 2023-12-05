/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

-- SIAC-8161_svecchiamento_anno_tipo_04112022.sql
-- caso provato in prod 2021 funzionava al 04.11.2022
-- fare ancora il 2021

select 
 stato.file_pagopa_stato_code,count(*)
from siac_t_file_pagopa file,siac_d_file_pagopa_stato stato
where stato.ente_proprietario_id=2
and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
and   file.file_pagopa_anno::integer=2022
group by  stato.file_pagopa_stato_code
--ANNULLATO	11
--ELABORATO_IN_CORSO_ER	1
--ELABORATO_OK	21730
--RIFIUTATO	60

select --count(*)
       stato.file_pagopa_stato_code,file.file_pagopa_id,
       file.file_pagopa_id_flusso,
       file.file_pagopa_anno,
       file.data_Creazione,
       file.data_cancellazione , file.validita_fine 
from siac_t_file_pagopa file,siac_d_file_pagopa_stato stato
where stato.ente_proprietario_id=2
and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
and   file.file_pagopa_anno::integer=2021
order by file.data_creazione desc
-- 21.802


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
and   file.file_pagopa_anno::integer=2021
and   r.file_pagopa_id =file.file_pagopa_id 
order by file.data_creazione desc
-- 21.741

select 
       stato.file_pagopa_stato_code,file.file_pagopa_id_flusso ,file.file_pagopa_id ,count(*) 
from siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_t_riconciliazione  r
where stato.ente_proprietario_id=2
and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
and   file.file_pagopa_anno::integer=2021
and   r.file_pagopa_id =file.file_pagopa_id 
group by stato.file_pagopa_stato_code,file.file_pagopa_id_flusso ,file.file_pagopa_id
--ANNULLATO	57
--ELABORATO_IN_CORSO_ER	6
--ELABORATO_OK	63187

select count(*) from pagopa_t_riconciliazione_det  det 
-- 6310527

select --count(*)
 stato.file_pagopa_stato_code,count(*) 
from siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_t_riconciliazione  r,pagopa_t_riconciliazione_Det det 
where stato.ente_proprietario_id=2
and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
and   file.file_pagopa_anno::integer=2021
and   r.file_pagopa_id =file.file_pagopa_id 
and   det.pagopa_ric_id=r.pagopa_ric_id
group by stato.file_pagopa_stato_code
--ANNULLATO	2316
--ELABORATO_IN_CORSO_ER	3896
--ELABORATO_OK	3494968


select --count(*)
 stato.file_pagopa_stato_code,count(*)
from siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_t_riconciliazione  r,pagopa_t_riconciliazione_Doc det 
where stato.ente_proprietario_id=2
and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
and   file.file_pagopa_anno::integer=2021
and   r.file_pagopa_id =file.file_pagopa_id 
and   det.pagopa_ric_id=r.pagopa_ric_id
group by stato.file_pagopa_stato_code
--ANNULLATO	72
--ELABORATO_IN_CORSO_ER	6
--ELABORATO_OK	66369


select --count(*)
 stato.file_pagopa_stato_code,count(*)
from siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_t_riconciliazione  r,pagopa_t_riconciliazione_Doc det ,pagopa_t_elaborazione_flusso  flusso 
where stato.ente_proprietario_id=2
and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
and   file.file_pagopa_anno::integer=2021
and   r.file_pagopa_id =file.file_pagopa_id 
and   det.pagopa_ric_id=r.pagopa_ric_id
and   flusso.pagopa_elab_flusso_id =det.pagopa_elab_flusso_id  
group by stato.file_pagopa_stato_code
--66447 
--ANNULLATO	72
--ELABORATO_IN_CORSO_ER	6
--ELABORATO_OK	66369

select distinct elab.pagopa_elab_data , elab.pagopa_elab_id , stato_elab.pagopa_elab_stato_code , stato.file_pagopa_stato_code ,file.file_pagopa_id 
from siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_t_riconciliazione  r,pagopa_t_riconciliazione_Doc det ,pagopa_t_elaborazione_flusso  flusso ,
pagopa_r_elaborazione_file  rfile ,pagopa_t_elaborazione  elab, pagopa_d_elaborazione_stato  stato_elab 
where stato.ente_proprietario_id=2
and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
and   file.file_pagopa_anno::integer=2021
and   r.file_pagopa_id =file.file_pagopa_id 
and   det.pagopa_ric_id=r.pagopa_ric_id
and   flusso.pagopa_elab_flusso_id =det.pagopa_elab_flusso_id  
and   rfile.pagopa_elab_id =flusso.pagopa_elab_id 
and    rfile.file_pagopa_id =file.file_pagopa_id 
and   elab.pagopa_elab_id =rfile.pagopa_elab_id 
and   stato_elab.pagopa_elab_stato_id =elab.pagopa_elab_stato_id 
--and   stato_elab.pagopa_elab_stato_code not in ('ELABORATO_OK')
and   stato_elab.pagopa_elab_stato_code  in ('ELABORATO_OK')

-- 19.541 NOT OK
-- 22.395 TUTTI
-- 2.854 OK

select --distinct elab.pagopa_elab_data , elab.pagopa_elab_id , stato_elab.pagopa_elab_stato_code , stato.file_pagopa_stato_code ,file.file_pagopa_id 
--stato_elab.pagopa_elab_stato_code,
stato.file_pagopa_stato_code ,count(*)
from siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_t_riconciliazione  r,pagopa_t_riconciliazione_Doc det ,pagopa_t_elaborazione_flusso  flusso ,
pagopa_r_elaborazione_file  rfile ,pagopa_t_elaborazione  elab, pagopa_d_elaborazione_stato  stato_elab 
where stato.ente_proprietario_id=2
and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
and   file.file_pagopa_anno::integer=2021
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
--ANNULLATO	72
--ELABORATO_IN_CORSO_ER	6
--ELABORATO_OK	66369


select *
from pagopa_d_elaborazione_svecchia_tipo tipo
where tipo.ente_proprietario_id =2

   update pagopa_d_elaborazione_svecchia_tipo tipo
   set     pagopa_elab_svecchia_delta_giorni=307,
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
(4094,0,"Elaborazione svecchiamento periodico rinconciliazione PAGOPA per  dataSvecchia=01/01/2022.")
-----
dataSvecchiaSqlQuery=select date_trunc('DAY','2022-11-04 19:08:37.271216'::timestamp)- interval '307 day' 
dataSvecchia=2022-01-01 00:00:00
---------- ELEABORAZIONE IN CORSO --------------
strMessaggio= backup pagopa_t_elaborazione - 
inseriti=117
 
inseriti=614
 
inseriti=10
 
strMessaggio= backup pagopa_t_elaborazione_flusso - 
inseriti=3087
 
inseriti=18321
 
inseriti=1820
 
strMessaggio= backup pagopa_t_riconciliazione_doc - 
inseriti=9989
 
inseriti=52508
 
inseriti=72
 
strMessaggio= backup pagopa_r_elaborazione_file - 
inseriti=3087
 
inseriti=18321
 
inseriti=10
 
strMessaggio= backup siac_t_file_pagopa - 
inseriti=21357
 
inseriti=11
 
inseriti=60
 
strMessaggio= backup pagopa_t_riconciliazione - 
inseriti=9851
 
inseriti=51534
 
inseriti=0
 
strMessaggio= backup pagopa_t_riconciliazione_det - 
inseriti=685431
 
inseriti=2727111
 
inseriti=2316
 
strMessaggio= backup pagopa_t_elaborazione_log - 
inseriti=51210
 
inseriti=316921
 
inseriti=40279
 
---------- INIZIO FASE CANCELLAZIONE --------------
strMessaggio= cancellazione pagopa_bck_t_registrounico_doc - 
cancellati=2120
strMessaggio= cancellazione pagopa_bck_t_doc_class - 
cancellati=0
strMessaggio= cancellazione pagopa_bck_t_doc_attr - 
cancellati=16960
strMessaggio= cancellazione pagopa_bck_t_doc_sog - 
cancellati=2120
strMessaggio= cancellazione pagopa_bck_t_subdoc_num - 
cancellati=2120
strMessaggio= cancellazione pagopa_bck_t_doc_stato - 
cancellati=11689
strMessaggio= cancellazione pagopa_bck_t_doc - 
cancellati=907
strMessaggio= cancellazione pagopa_bck_t_subdoc_movgest_ts - 
cancellati=370
strMessaggio= cancellazione pagopa_bck_t_subdoc_prov_cassa - 
cancellati=370
strMessaggio= cancellazione pagopa_bck_t_subdoc_atto_amm - 
cancellati=318
strMessaggio= cancellazione pagopa_bck_t_subdoc_attr - 
cancellati=1850
strMessaggio= cancellazione pagopa_bck_t_subdoc - 
cancellati=370
strMessaggio= cancellazione pagopa_t_elaborazione_log - 
cancellati=378290
cancellati=33504
cancellati=34
strMessaggio= cancellazione pagopa_t_riconciliazione_det - 
cancellati=625426
cancellati=2701623
cancellati=2316
strMessaggio= cancellazione pagopa_t_riconciliazione_doc (C)- 
cancellati=10034
cancellati=54176
cancellati=72
strMessaggio= cancellazione pagopa_t_riconciliazione - 
cancellati=9843
cancellati=51197
cancellati=57
strMessaggio= cancellazione pagopa_t_elaborazione_flusso (B) - 
cancellati=3087
cancellati=18931
cancellati=0
strMessaggio= cancellazione pagopa_r_elaborazione_file - 
cancellati=3087
cancellati=18931
strMessaggio= cancellazione pagopa_t_modifica_elab x pagopa_r_elaborazione_file ANNULLATI - 
cancellati=0
strMessaggio= cancellazione pagopa_t_elaborazione x pagopa_r_elaborazione_file ANNULLATI - 
cancellati=0
cancellati=0
cancellati=2
strMessaggio= cancellazione siac_t_file_pagopa - 
cancellati=21428
altri_record=0
strMessaggio= cancellazione pagopa_r_elaborazione_file - 
pagopa_r_elaborazione_file cancellati=0
strMessaggio= cancellazione pagopa_t_modifica_elab - 
cancellati=7551
strMessaggio= cancellazione pagopa_t_elaborazione - 
cancellati=117
cancellati=619
countDel=3979519
strMessaggio=Fine fnc_pagopa_t_elaborazione_riconc_svecchia -  cancellati complessivamente 3979519 Chiusura elaborazione [pagopa_t_elaborazione_svecchia].
---------- ELABORAZIONE TERMINATA --------------
Fine fnc_pagopa_t_elaborazione_riconc_svecchia -  cancellati complessivamente 3979519Elaborazione svecchiamento periodico rinconciliazione PAGOPA per  dataSvecchia=01/01/2022.
