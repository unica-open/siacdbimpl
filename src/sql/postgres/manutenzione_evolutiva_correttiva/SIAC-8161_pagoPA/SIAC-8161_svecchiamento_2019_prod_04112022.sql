/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

-- SIAC-8161_svecchiamento_2019_prod_04112022.sql

select 
 stato.file_pagopa_stato_code,count(*)
from siac_t_file_pagopa file,siac_d_file_pagopa_stato stato
where stato.ente_proprietario_id=2
and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
and   file.file_pagopa_anno::integer=2019
group by  stato.file_pagopa_stato_code
-- ELABORATO_OK	81

select --count(*)
       stato.file_pagopa_stato_code,file.file_pagopa_id,
       file.file_pagopa_id_flusso,
       file.file_pagopa_anno,
       file.data_Creazione,
       file.data_cancellazione , file.validita_fine 
from siac_t_file_pagopa file,siac_d_file_pagopa_stato stato
where stato.ente_proprietario_id=2
and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
and   file.file_pagopa_anno::integer=2019
order by file.data_creazione desc
-- 81

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
and   file.file_pagopa_anno::integer=2019
and   r.file_pagopa_id =file.file_pagopa_id 
order by file.data_creazione desc
-- 81

select 
       stato.file_pagopa_stato_code,count(*) 
from siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_t_riconciliazione  r
where stato.ente_proprietario_id=2
and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
and   file.file_pagopa_anno::integer=2019
and   r.file_pagopa_id =file.file_pagopa_id 
group by stato.file_pagopa_stato_code
-- ELABORATO_OK	99

select count(*) from pagopa_t_riconciliazione_det  det 
-- 7964274
--7963908


select --count(*)
 stato.file_pagopa_stato_code,count(*) 
from siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_t_riconciliazione  r,pagopa_t_riconciliazione_Det det 
where stato.ente_proprietario_id=2
and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
and   file.file_pagopa_anno::integer=2019
and   r.file_pagopa_id =file.file_pagopa_id 
and   det.pagopa_ric_id=r.pagopa_ric_id
group by stato.file_pagopa_stato_code
-- 366
-- ELABORATO_OK	366


select-- count(*)
 stato.file_pagopa_stato_code,count(*)
from siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_t_riconciliazione  r,pagopa_t_riconciliazione_Doc det 
where stato.ente_proprietario_id=2
and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
and   file.file_pagopa_anno::integer=2019
and   r.file_pagopa_id =file.file_pagopa_id 
and   det.pagopa_ric_id=r.pagopa_ric_id
group by stato.file_pagopa_stato_code
-- 31
-- ELABORATO_OK	31


select --count(*)
stato.file_pagopa_stato_code,count(*)
from siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_t_riconciliazione  r,pagopa_t_riconciliazione_Doc det ,pagopa_t_elaborazione_flusso  flusso 
where stato.ente_proprietario_id=2
and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
and   file.file_pagopa_anno::integer=2019
and   r.file_pagopa_id =file.file_pagopa_id 
and   det.pagopa_ric_id=r.pagopa_ric_id
and   flusso.pagopa_elab_flusso_id =det.pagopa_elab_flusso_id  
group by stato.file_pagopa_stato_code
-- ELABORATO_OK	31

select distinct elab.pagopa_elab_data , elab.pagopa_elab_id , stato_elab.pagopa_elab_stato_code , stato.file_pagopa_stato_code ,file.file_pagopa_id 
from siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_t_riconciliazione  r,pagopa_t_riconciliazione_Doc det ,pagopa_t_elaborazione_flusso  flusso ,
pagopa_r_elaborazione_file  rfile ,pagopa_t_elaborazione  elab, pagopa_d_elaborazione_stato  stato_elab 
where stato.ente_proprietario_id=2
and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
and   file.file_pagopa_anno::integer=2019
and   r.file_pagopa_id =file.file_pagopa_id 
and   det.pagopa_ric_id=r.pagopa_ric_id
and   flusso.pagopa_elab_flusso_id =det.pagopa_elab_flusso_id  
and   rfile.pagopa_elab_id =flusso.pagopa_elab_id 
and    rfile.file_pagopa_id =file.file_pagopa_id 
and   elab.pagopa_elab_id =rfile.pagopa_elab_id 
and   stato_elab.pagopa_elab_stato_id =elab.pagopa_elab_stato_id 
and   stato_elab.pagopa_elab_stato_code not in ('ELABORATO_OK')
-- 31

select --distinct elab.pagopa_elab_data , elab.pagopa_elab_id , stato_elab.pagopa_elab_stato_code , stato.file_pagopa_stato_code ,file.file_pagopa_id 
--stato_elab.pagopa_elab_stato_code,
stato.file_pagopa_stato_code ,count(*)
from siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_t_riconciliazione  r,pagopa_t_riconciliazione_Doc det ,pagopa_t_elaborazione_flusso  flusso ,
pagopa_r_elaborazione_file  rfile ,pagopa_t_elaborazione  elab, pagopa_d_elaborazione_stato  stato_elab 
where stato.ente_proprietario_id=2
and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
and   file.file_pagopa_anno::integer=2019
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
-- ELABORATO_OK	31

select *
from pagopa_d_elaborazione_svecchia_tipo tipo
where tipo.ente_proprietario_id =2

   update pagopa_d_elaborazione_svecchia_tipo tipo
   set     pagopa_elab_svecchia_delta_giorni=1038,
            pagopa_elab_svecchia_tipo_fl_back =true,
           data_modifica=now(),
           login_operazione=tipo.login_operazione||'-SIAC-8161'
   where tipo.ente_proprietario_id=2
   and   tipo.pagopa_elab_svecchia_tipo_code='PERIODICO'
   -- 470
   
     select date_trunc('DAY',now()::timestamp)- ( interval '307 days'); -- 2021
     select date_trunc('DAY',now()::timestamp)- ( interval '668 days'); -- 2020
     select date_trunc('DAY',now()::timestamp)- ( interval '1038 days'); -- 2019
     
     
select 
fnc_pagopa_t_elaborazione_riconc_svecchia_ss
(
2,
'SIAC-8161',
now()::timestamp)     
--(4081,0,"Elaborazione svecchiamento periodico rinconciliazione PAGOPA per  dataSvecchia=01/01/2020.")



select--  count(*)
  stato.file_pagopa_stato_code,file.file_pagopa_id,
       file.file_pagopa_id_flusso,
       file.file_pagopa_anno,
       file.data_Creazione,
       file.data_cancellazione , file.validita_fine 
from siac_t_file_pagopa file,siac_d_file_pagopa_stato stato
where stato.ente_proprietario_id=2
and   file.file_pagopa_stato_id=stato.file_pagopa_stato_id
and   file.file_pagopa_anno::integer=2019
order by file.data_creazione desc

ALTER TABLE siac.pagopa_t_riconciliazione_det DROP  constraint pagopa_t_riconciliazione_pagopa_t_riconciliazione_det;

delete from pagopa_t_riconciliazione  ric 
using siac_t_file_pagopa file, siac_d_file_pagopa_stato  stato 
where stato.ente_proprietario_id=2
and     stato.file_pagopa_stato_code='ELABORATO_OK' 
and     file.file_pagopa_stato_id=stato.file_pagopa_stato_id 
and     file.file_pagopa_anno::integer=2019
and     ric.file_pagopa_id =file.file_pagopa_id 
and     not exists (select 1 from pagopa_t_riconciliazione_doc doc where doc.pagopa_ric_id=ric.pagopa_ric_id)

ALTER TABLE siac.pagopa_t_riconciliazione_det ADD CONSTRAINT pagopa_t_riconciliazione_pagopa_t_riconciliazione_det FOREIGN KEY (pagopa_ric_id) REFERENCES pagopa_t_riconciliazione(pagopa_ric_id);


delete from pagopa_t_elaborazione_log ll
using siac_t_file_pagopa file, siac_d_file_pagopa_stato  stato 
where stato.ente_proprietario_id=2
and     stato.file_pagopa_stato_code='ELABORATO_OK' 
and     file.file_pagopa_stato_id=stato.file_pagopa_stato_id 
and     file.file_pagopa_anno::integer=2019
and     ll.pagopa_elab_file_id=file.file_pagopa_id 
and     not exists (select 1 from pagopa_t_riconciliazione ric where ric.file_pagopa_id=file.file_pagopa_id)

delete from siac_t_file_pagopa file 
using  siac_d_file_pagopa_stato  stato 
where stato.ente_proprietario_id=2
and     stato.file_pagopa_stato_code='ELABORATO_OK' 
and     file.file_pagopa_stato_id=stato.file_pagopa_stato_id 
and     file.file_pagopa_anno::integer=2019
and     not exists (select 1 from pagopa_t_riconciliazione ric where ric.file_pagopa_id=file.file_pagopa_id)

--------

dataSvecchiaSqlQuery=select date_trunc('DAY','2022-11-04 17:16:21.649184'::timestamp)- interval '1038 day' 
dataSvecchia=2020-01-01 00:00:00
---------- ELEABORAZIONE IN CORSO --------------
strMessaggio= backup pagopa_t_elaborazione - 
inseriti=0
 
inseriti=1
 
inseriti=0
 
strMessaggio= backup pagopa_t_elaborazione_flusso - 
inseriti=0
 
inseriti=31
 
inseriti=0
 
strMessaggio= backup pagopa_t_riconciliazione_doc - 
inseriti=0
 
inseriti=31
 
inseriti=0
 
strMessaggio= backup pagopa_r_elaborazione_file - 
inseriti=0
 
inseriti=31
 
inseriti=0
 
strMessaggio= backup siac_t_file_pagopa - 
inseriti=31
 
inseriti=0
 
inseriti=0
 
strMessaggio= backup pagopa_t_riconciliazione - 
inseriti=0
 
inseriti=31
 
inseriti=0
 
strMessaggio= backup pagopa_t_riconciliazione_det - 
inseriti=0
 
inseriti=366
 
inseriti=0
 
strMessaggio= backup pagopa_t_elaborazione_log - 
inseriti=0
 
inseriti=380
 
inseriti=33
 
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
cancellati=380
cancellati=33
cancellati=0
strMessaggio= cancellazione pagopa_t_riconciliazione_det - 
cancellati=0
cancellati=366
cancellati=0
strMessaggio= cancellazione pagopa_t_riconciliazione_doc (C)- 
cancellati=0
cancellati=31
cancellati=0
strMessaggio= cancellazione pagopa_t_riconciliazione - 
cancellati=0
cancellati=31
cancellati=0
strMessaggio= cancellazione pagopa_t_elaborazione_flusso (B) - 
cancellati=0
cancellati=31
cancellati=0
strMessaggio= cancellazione pagopa_r_elaborazione_file - 
cancellati=0
cancellati=31
strMessaggio= cancellazione pagopa_t_modifica_elab x pagopa_r_elaborazione_file ANNULLATI - 
cancellati=0
strMessaggio= cancellazione pagopa_t_elaborazione x pagopa_r_elaborazione_file ANNULLATI - 
cancellati=0
cancellati=0
strMessaggio= cancellazione siac_t_file_pagopa - 
cancellati=31
altri_record=0
strMessaggio= cancellazione pagopa_r_elaborazione_file - 
pagopa_r_elaborazione_file cancellati=0
strMessaggio= cancellazione pagopa_t_modifica_elab - 
cancellati=0
strMessaggio= cancellazione pagopa_t_elaborazione - 
cancellati=0
cancellati=1
countDel=935
strMessaggio=Fine fnc_pagopa_t_elaborazione_riconc_svecchia -  cancellati complessivamente 935 Chiusura elaborazione [pagopa_t_elaborazione_svecchia].
---------- ELABORAZIONE TERMINATA --------------
Fine fnc_pagopa_t_elaborazione_riconc_svecchia -  cancellati complessivamente 935Elaborazione svecchiamento periodico rinconciliazione PAGOPA per  dataSvecchia=01/01/2020.


