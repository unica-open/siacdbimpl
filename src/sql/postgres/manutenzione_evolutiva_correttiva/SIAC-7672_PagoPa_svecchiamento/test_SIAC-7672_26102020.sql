/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿select stato_file.file_pagopa_stato_code, file.file_pagopa_id_flusso,file.file_pagopa_id
from siac_t_file_pagopa file, siac_d_file_pagopa_stato stato_file
where stato_file.ente_proprietario_id=2
and   stato_file.file_pagopa_stato_id=file.file_pagopa_stato_id
and   file.data_cancellazione is null
order by file.file_pagopa_id desc
-- 11

select stato.pagopa_elab_stato_code , elab.pagopa_elab_id, elab.pagopa_elab_note,
       stato_file.file_pagopa_stato_code,file.file_pagopa_id, file.file_pagopa_id_flusso,
	   doc.pagopa_ric_doc_stato_elab,doc.pagopa_ric_id,doc.*
from pagopa_t_elaborazione elab, pagopa_d_elaborazione_stato stato,
     pagopa_r_elaborazione_file r, siac_t_file_pagopa file, siac_d_file_pagopa_stato stato_file,
     pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
where stato.ente_proprietario_id=2
and   elab.pagopa_elab_stato_id=stato.pagopa_elab_stato_id
and   r.pagopa_elab_id=elab.pagopa_elab_id
and   file.file_pagopa_id=r.file_pagopa_id
and   stato_file.file_pagopa_stato_id=file.file_pagopa_stato_id
and   flusso.pagopa_elab_id=elab.pagopa_elab_id
and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
and   doc.file_pagopa_id=file.file_pagopa_id
and   doc.pagopa_ric_doc_stato_elab !='S'
and   ( doc.pagopa_ric_doc_flag_con_dett=false  or doc.pagopa_ric_doc_flag_dett=true)
and   stato.pagopa_elab_stato_code not in ('ELABORATO_OK', 'ANNULLATO','RIFIUTATO' )
and   stato.pagopa_elab_stato_code not like 'ELABORATO_IN_CORSO%'
--and   elab.pagopa_elab_id<332
--and   elab.pagopa_elab_id>=331
and   r.data_cancellazione is null
and   r.validita_fine is null
and   doc.data_cancellazione is null
and   elab.data_cancellazione is null
and   flusso.data_cancellazione is null
and   file.data_cancellazione is null
order by elab.pagopa_elab_id desc, file.file_pagopa_id,doc.pagopa_ric_id

-- 373

select stato.pagopa_elab_stato_code , elab.pagopa_elab_id, elab.pagopa_elab_note,
       stato_file.file_pagopa_stato_code,file.file_pagopa_id, file.file_pagopa_id_flusso,
	   doc.pagopa_ric_doc_stato_elab,doc.pagopa_ric_id,doc.*
from pagopa_t_elaborazione elab, pagopa_d_elaborazione_stato stato,
     pagopa_r_elaborazione_file r, siac_t_file_pagopa file, siac_d_file_pagopa_stato stato_file,
     pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
where stato.ente_proprietario_id=2
and   elab.pagopa_elab_stato_id=stato.pagopa_elab_stato_id
and   r.pagopa_elab_id=elab.pagopa_elab_id
and   file.file_pagopa_id=r.file_pagopa_id
and   stato_file.file_pagopa_stato_id=file.file_pagopa_stato_id
and   flusso.pagopa_elab_id=elab.pagopa_elab_id
and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
and   doc.file_pagopa_id=file.file_pagopa_id
and   doc.pagopa_ric_doc_stato_elab !='S'
and   ( doc.pagopa_ric_doc_flag_con_dett=false  or doc.pagopa_ric_doc_flag_dett=true)
--and   stato.pagopa_elab_stato_code not in ('ELABORATO_OK', 'ANNULLATO','RIFIUTATO' )
--and   stato.pagopa_elab_stato_code not like 'ELABORATO_IN_CORSO%'
and   elab.pagopa_elab_id=390
--and   elab.pagopa_elab_id>=331
and   r.data_cancellazione is null
and   r.validita_fine is null
and   doc.data_cancellazione is null
and   elab.data_cancellazione is null
and   flusso.data_cancellazione is null
and   file.data_cancellazione is null
order by elab.pagopa_elab_id desc, file.file_pagopa_id,doc.pagopa_ric_id

select stato.pagopa_elab_stato_code , elab.pagopa_elab_id, elab.pagopa_elab_note,
       stato_file.file_pagopa_stato_code,file.file_pagopa_id, file.file_pagopa_id_flusso,
	   doc.pagopa_ric_doc_stato_elab,doc.pagopa_ric_id,doc.*
from pagopa_t_elaborazione elab, pagopa_d_elaborazione_stato stato,
     pagopa_r_elaborazione_file r, siac_t_file_pagopa file, siac_d_file_pagopa_stato stato_file,
     pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
where stato.ente_proprietario_id=2
and   elab.pagopa_elab_stato_id=stato.pagopa_elab_stato_id
and   r.pagopa_elab_id=elab.pagopa_elab_id
and   file.file_pagopa_id=r.file_pagopa_id
and   stato_file.file_pagopa_stato_id=file.file_pagopa_stato_id
and   flusso.pagopa_elab_id=elab.pagopa_elab_id
and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
and   doc.file_pagopa_id=file.file_pagopa_id
and   doc.pagopa_ric_doc_stato_elab !='S'
and   (doc.pagopa_ric_doc_flag_con_dett=false  or doc.pagopa_ric_doc_flag_dett=true)
and   stato.pagopa_elab_stato_code not in ('ELABORATO_OK', 'ANNULLATO','RIFIUTATO' )
and   stato.pagopa_elab_stato_code not like 'ELABORATO_IN_CORSO%'
and   elab.pagopa_elab_id<390
and   elab.pagopa_elab_id>=--331
--and   exists
(
select distinct elab_prec.pagopa_elab_id
from  pagopa_t_elaborazione elab_prec, pagopa_d_elaborazione_stato stato_prec,
      pagopa_t_elaborazione_flusso flusso_prec, pagopa_t_riconciliazione_doc doc_prec
where doc_prec.pagopa_ric_id=doc.pagopa_ric_id
and   (doc_prec.pagopa_ric_doc_flag_con_dett=false  or doc_prec.pagopa_ric_doc_flag_dett=true)
and   doc_prec.pagopa_ric_doc_stato_elab !='S'
and   flusso_prec.pagopa_elab_flusso_id=doc_prec.pagopa_elab_flusso_id
and   elab_prec.pagopa_elab_id=flusso_prec.pagopa_elab_id
and   stato_prec.pagopa_elab_stato_id=elab_prec.pagopa_elab_stato_id
and   stato_prec.pagopa_elab_stato_code not in ('ELABORATO_OK', 'ANNULLATO','RIFIUTATO' )
and   stato_prec.pagopa_elab_stato_code not like 'ELABORATO_IN_CORSO%'
and   elab_prec.pagopa_elab_id<388
and   doc_prec.data_cancellazione is null
and   flusso_prec.data_cancellazione is null
and   elab_prec.data_cancellazione is null
order by elab_prec.pagopa_elab_id desc
limit 1
)
and   r.data_cancellazione is null
and   r.validita_fine is null
and   doc.data_cancellazione is null
and   elab.data_cancellazione is null
and   flusso.data_cancellazione is null
and   file.data_cancellazione is null
order by elab.pagopa_elab_id desc, file.file_pagopa_id,doc.pagopa_ric_id

--- 7692, 7969, 7970

-- 7692, 7969, 7970 - 390

select stato.pagopa_elab_stato_code , elab.pagopa_elab_id, elab.pagopa_elab_note,
       stato_file.file_pagopa_stato_code,file.file_pagopa_id, file.file_pagopa_id_flusso,
	   doc.pagopa_ric_doc_stato_elab,doc.pagopa_ric_id,doc.*
from pagopa_t_elaborazione elab, pagopa_d_elaborazione_stato stato,
     pagopa_r_elaborazione_file r, siac_t_file_pagopa file, siac_d_file_pagopa_stato stato_file,
     pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
where stato.ente_proprietario_id=2
and   elab.pagopa_elab_stato_id=stato.pagopa_elab_stato_id
and   r.pagopa_elab_id=elab.pagopa_elab_id
and   file.file_pagopa_id=r.file_pagopa_id
and   stato_file.file_pagopa_stato_id=file.file_pagopa_stato_id
and   flusso.pagopa_elab_id=elab.pagopa_elab_id
and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
and   doc.file_pagopa_id=file.file_pagopa_id
and   doc.pagopa_ric_doc_stato_elab !='S'
and   (doc.pagopa_ric_doc_flag_con_dett=false  or doc.pagopa_ric_doc_flag_dett=true)
--and   stato.pagopa_elab_stato_code not in ('ELABORATO_OK', 'ANNULLATO','RIFIUTATO' )
--and   stato.pagopa_elab_stato_code not like 'ELABORATO_IN_CORSO%'
and   exists
(
   select 1
   from  pagopa_t_elaborazione_flusso flusso_cur,
         pagopa_t_riconciliazione_doc doc_cur
   where flusso_cur.pagopa_elab_id=392
   and   doc_cur.pagopa_elab_flusso_id=flusso_CUR.pagopa_elab_flusso_id
   and   doc_cur.pagopa_ric_doc_stato_elab !='S'
   and   doc_cur.pagopa_ric_id=doc.pagopa_ric_id
   and   ( doc_cur.pagopa_ric_doc_flag_con_dett=false  or doc_cur.pagopa_ric_doc_flag_dett=true)
   and   doc_cur.data_cancellazione is null
   and   flusso_cur.data_cancellazione is null
)
and   elab.pagopa_elab_id<392
and   elab.pagopa_elab_id>=--331
--and   exists
(
select distinct elab_prec.pagopa_elab_id
from  pagopa_t_elaborazione elab_prec, pagopa_d_elaborazione_stato stato_prec,
      pagopa_t_elaborazione_flusso flusso_prec, pagopa_t_riconciliazione_doc doc_prec
where doc_prec.pagopa_ric_id=doc.pagopa_ric_id
and   (doc_prec.pagopa_ric_doc_flag_con_dett=false  or doc_prec.pagopa_ric_doc_flag_dett=true)
and   doc_prec.pagopa_ric_doc_stato_elab !='S'
and   flusso_prec.pagopa_elab_flusso_id=doc_prec.pagopa_elab_flusso_id
and   elab_prec.pagopa_elab_id=flusso_prec.pagopa_elab_id
and   stato_prec.pagopa_elab_stato_id=elab_prec.pagopa_elab_stato_id
--and   stato_prec.pagopa_elab_stato_code not in ('ELABORATO_OK', 'ANNULLATO','RIFIUTATO' )
--and   stato_prec.pagopa_elab_stato_code not like 'ELABORATO_IN_CORSO%'
and   elab_prec.pagopa_elab_id<392
and   doc_prec.data_cancellazione is null
and   flusso_prec.data_cancellazione is null
and   elab_prec.data_cancellazione is null
order by elab_prec.pagopa_elab_id desc
limit 1
)
and   r.data_cancellazione is null
and   r.validita_fine is null
and   doc.data_cancellazione is null
and   elab.data_cancellazione is null
and   flusso.data_cancellazione is null
and   file.data_cancellazione is null
order by elab.pagopa_elab_id desc, file.file_pagopa_id,doc.pagopa_ric_id

-- 584

-- test di questo caso 374 a 354
-- 8377

-- test 333 235
-- 6663 331
-- 332, 331, 330
select stato.pagopa_elab_stato_code , elab.pagopa_elab_id, elab.pagopa_elab_note,
       stato_file.file_pagopa_stato_code,file.file_pagopa_id, file.file_pagopa_id_flusso,
	   doc.pagopa_ric_doc_stato_elab,doc.pagopa_ric_id,doc.*
from pagopa_t_elaborazione elab, pagopa_d_elaborazione_stato stato,
     pagopa_r_elaborazione_file r, siac_t_file_pagopa file, siac_d_file_pagopa_stato stato_file,
     pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
where stato.ente_proprietario_id=2
and   elab.pagopa_elab_stato_id=stato.pagopa_elab_stato_id
and   r.pagopa_elab_id=elab.pagopa_elab_id
and   file.file_pagopa_id=r.file_pagopa_id
and   stato_file.file_pagopa_stato_id=file.file_pagopa_stato_id
and   flusso.pagopa_elab_id=elab.pagopa_elab_id
and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
and   doc.file_pagopa_id=file.file_pagopa_id
--and   file.file_pagopa_id=7692
--and   doc.pagopa_ric_id in (8377,8378)
--and   elab.pagopa_elab_id=390
--and   doc.pagopa_ric_id=6663
--and   doc.pagopa_ric_doc_stato_elab !='S'
--and   ( doc.pagopa_ric_doc_flag_con_dett=false  or doc.pagopa_ric_doc_flag_dett=true)
--and   stato.pagopa_elab_stato_code not in ('ELABORATO_OK', 'ANNULLATO','RIFIUTATO' )
--and   stato.pagopa_elab_stato_code not like 'ELABORATO_IN_CORSO%'
and   r.data_cancellazione is null
and   r.validita_fine is null
and   doc.data_cancellazione is null
and   elab.data_cancellazione is null
and   flusso.data_cancellazione is null
and   file.data_cancellazione is null
order by elab.pagopa_elab_id desc, file.file_pagopa_id,doc.pagopa_ric_id



select flusso.pagopa_elab_id,doc.*
	 from  pagopa_t_elaborazione_flusso flusso,
           pagopa_t_riconciliazione_doc doc
	 where flusso.pagopa_elab_id<25
	 and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
	 and   doc.pagopa_ric_doc_stato_elab !='S'
	 and   ( doc.pagopa_ric_doc_flag_con_dett=false  or doc.pagopa_ric_doc_flag_dett=true)
     and   exists
     (
     	 select 1
		 from  pagopa_t_elaborazione_flusso flusso_cur,
               pagopa_t_riconciliazione_doc doc_cur
   	     where flusso_cur.pagopa_elab_id=25
	 	 and   doc_cur.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		 and   doc_cur.pagopa_ric_doc_stato_elab !='S'
         and   doc_cur.pagopa_ric_id=doc.pagopa_ric_id
		 and   ( doc_cur.pagopa_ric_doc_flag_con_dett=false  or doc_cur.pagopa_ric_doc_flag_dett=true)
		 and   doc_cur.data_cancellazione is null
		 and   flusso_cur.data_cancellazione is null
     )
	 and   doc.data_cancellazione is null
	 and   flusso.data_cancellazione is null
	 order by flusso.pagopa_elab_id, doc.pagopa_ric_id
-- elab_id=21
-- 533
-- 534
-- 546
-- 547
-- 548
-- 558
-- 559
-- 560

-- 460
-- 472
-- 482

-- 58
-- 70
-- 80

rollback;
begin;
select
fnc_pagopa_t_elaborazione_riconc_svecchia_err
(
  390,
  2020,
  2,
  'SIAC-7672',
  now()::timestamp
);

rollback;
begin;
select
fnc_pagopa_t_elaborazione_riconc
(
  2,
  'SIAC-7672',
  now()::timestamp
);
(-1,-1,-1,"ELABORAZIONE PAGOPA.TERMINE KO.ELABORAZIONE RINCONCILIAZIONE PAGOPA PER ID. ELABORAZIONE FILEPAGOPAELABID=381 ANNOBILANCIOELAB=2020. GESTIONE SCARTI DI ELABORAZIONE. VERIFICA ANNOBILANCIO INDICATO SU DETTAGLI DI RICONCILIAZIONE.  DATI NON PRESENTI..")


select *
from pagopa_t_riconciliazione_Doc ric
where ric.ente_proprietario_id=2
and   ric.login_operazione like '%LIBERA-SIAC-7672'
-- 7692 ancora scarti
--- 7969 , 7970, 7971

select doc.*
from pagopa_t_riconciliazione_Doc ric,pagopa_t_riconciliazione  doc
where ric.ente_proprietario_id=2
and   ric.login_operazione like '%LIBERA-SIAC-7672'
and   doc.pagopa_ric_id=ric.pagopa_ric_id

select RIC.*
from pagopa_t_riconciliazione_Doc ric,pagopa_t_riconciliazione  doc
where ric.ente_proprietario_id=2
--and   ric.login_operazione like '%LIBERA-SIAC-7672'
and   doc.pagopa_ric_id=ric.pagopa_ric_id
AND   RIC.file_pagopa_id IN (7966)


select *
from pagopa_t_riconciliazione ric
where ric.ente_proprietario_id=2
and   ric.file_pagopa_id=7966
-- 8377, 8378 ko

-- file_pagopa_id 7969 7970

select stato.pagopa_elab_stato_code , elab.pagopa_elab_id, elab.pagopa_elab_note,
       stato_file.file_pagopa_stato_code,file.file_pagopa_id, file.file_pagopa_id_flusso,
	   doc.pagopa_ric_doc_stato_elab,doc.pagopa_ric_id,doc.*
from pagopa_t_elaborazione elab, pagopa_d_elaborazione_stato stato,
     pagopa_r_elaborazione_file r, siac_t_file_pagopa file, siac_d_file_pagopa_stato stato_file,
     pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
where stato.ente_proprietario_id=2
and   elab.pagopa_elab_stato_id=stato.pagopa_elab_stato_id
and   r.pagopa_elab_id=elab.pagopa_elab_id
and   file.file_pagopa_id=r.file_pagopa_id
and   stato_file.file_pagopa_stato_id=file.file_pagopa_stato_id
and   flusso.pagopa_elab_id=elab.pagopa_elab_id
and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
and   doc.file_pagopa_id=file.file_pagopa_id
--and   doc.pagopa_ric_id in (8777,8778,8779)
and   file.file_pagopa_id in  (7692,7969 , 7970, 7971,7966)
--and   elab.pagopa_elab_id=373
--and   doc.pagopa_ric_id=6663
--and   doc.pagopa_ric_doc_stato_elab !='S'
--and   ( doc.pagopa_ric_doc_flag_con_dett=false  or doc.pagopa_ric_doc_flag_dett=true)
--and   stato.pagopa_elab_stato_code not in ('ELABORATO_OK', 'ANNULLATO','RIFIUTATO' )
--and   stato.pagopa_elab_stato_code not like 'ELABORATO_IN_CORSO%'
--and   r.data_cancellazione is null
--and   r.validita_fine is null
--and   doc.data_cancellazione is null
--and   elab.data_cancellazione is null
and   flusso.data_cancellazione is null
and   file.data_cancellazione is null
order by elab.pagopa_elab_id desc, file.file_pagopa_id,doc.pagopa_ric_id
-- 7971, 7970, 7969,  --  elab  380 annullata e non c'è altro questi vengono chiusi

-- 7692 -- 63 rec -- elab 373 che dovrebbe essere cancellata

select *
from pagopa_d_elaborazione_svecchia_tipo tipo
where tipo.ente_proprietario_id=2

select *
from pagopa_t_elaborazione_svecchia elab
where elab.ente_proprietario_id=2
order by elab.pagopa_elab_svecchia_id desc
-- 4
-- FINE SVECCHIAMENTO PUNTUALE ELAB. IN ERRORE. ELAB. ID=331 CANCELLATI COMPLESSIVAMENTE 617 PAGOPA_T_RICONCILIAZIONE_DOC.
-- FINE SVECCHIAMENTO PUNTUALE ELAB. IN ERRORE. ELAB. ID=373 CANCELLATI COMPLESSIVAMENTE 620 PAGOPA_T_RICONCILIAZIONE_DOC.
FINE SVECCHIAMENTO PUNTUALE ELAB. IN ERRORE. ELAB. ID=386 CANCELLATI COMPLESSIVAMENTE 620 PAGOPA_T_RICONCILIAZIONE_DOC.
FINE SVECCHIAMENTO PUNTUALE ELAB. IN ERRORE. ELAB. ID=389 CANCELLATI COMPLESSIVAMENTE 620 PAGOPA_T_RICONCILIAZIONE_DOC.
FINE SVECCHIAMENTO PUNTUALE ELAB. IN ERRORE. ELAB. ID=390 CANCELLATI COMPLESSIVAMENTE 3 PAGOPA_T_RICONCILIAZIONE_DOC.
FINE SVECCHIAMENTO PUNTUALE ELAB. IN ERRORE. ELAB. ID=392 CANCELLATI COMPLESSIVAMENTE 5 PAGOPA_T_RICONCILIAZIONE_DOC.
FINE SVECCHIAMENTO PUNTUALE ELAB. IN ERRORE. ELAB. ID=397 CANCELLATI COMPLESSIVAMENTE 5 PAGOPA_T_RICONCILIAZIONE_DOC.
FINE SVECCHIAMENTO PUNTUALE ELAB. IN ERRORE. ELAB. ID=398 CANCELLATI COMPLESSIVAMENTE 5 PAGOPA_T_RICONCILIAZIONE_DOC.
select *
from pagopa_t_bck_riconciliazione_doc doc
where doc.pagopa_elab_svecchia_id=21
and  doc.pagopa_elab_flusso_id=26715
order by doc.pagopa_ric_id

select doc.pagopa_elab_id
from pagopa_t_bck_elaborazione_flusso doc
where doc.pagopa_elab_svecchia_id=21
and   doc.pagopa_elab_flusso_id=26715

select ric.*
from pagopa_t_elaborazione_flusso doc,pagopa_t_riconciliazione_doc  ric
where doc.pagopa_elab_flusso_id=26718
and   ric.pagopa_elab_flusso_id=doc.pagopa_elab_flusso_id


select flusso.pagopa_elab_flusso_id, rfile.*
        from pagopa_t_elaborazione_flusso flusso,pagopa_r_elaborazione_file rfile,
             pagopa_t_riconciliazione_doc doc,pagopa_t_riconciliazione ric
        where flusso.pagopa_elab_id=390
        and   flusso.pagopa_elab_flusso_id!=26715
        and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
        and   ric.pagopa_ric_id=doc.pagopa_ric_id
        and   ric.file_pagopa_id=rfile.file_pagopa_id
        and   rfile.pagopa_elab_id=flusso.pagopa_elab_id
        and   rfile.file_pagopa_id=7692;


select doc.pagopa_elab_id, r.*
from pagopa_t_bck_elaborazione_flusso doc,pagopa_t_elaborazione elab,pagopa_r_elaborazione_file r,
siac_t_file_pagopa file
where doc.pagopa_elab_svecchia_id=20
and   elab.pagopa_elab_id=doc.pagopa_elab_id
and   r.pagopa_elab_id=elab.pagopa_elab_id
and   file.file_pagopa_id=r.file_pagopa_id

select *
from pagopa_r_bck_elaborazione_file doc
where doc.pagopa_elab_svecchia_id=21

select *
from pagopa_t_bck_elaborazione doc
where doc.pagopa_elab_svecchia_id=21
--332,372, 89

select r.*
from pagopa_t_elaborazione doc,pagopa_r_elaborazione_file r
where doc.pagopa_elab_id=397
and   r.pagopa_elab_id=doc.pagopa_elab_id

select file.file_pagopa_id, ric_doc.*
from pagopa_t_elaborazione doc,pagopa_r_elaborazione_file r,siac_t_file_pagopa file,
    pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc ric,
    pagopa_t_riconciliazione ric_doc
where doc.pagopa_elab_id=390
and   r.pagopa_elab_id=doc.pagopa_elab_id
and   file.file_pagopa_id=r.file_pagopa_id
and   flusso.pagopa_elab_id=doc.pagopa_elab_id
and   ric.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
and   ric_doc.pagopa_ric_id=ric.pagopa_ric_id
and   ric_doc.file_pagopa_id=file.file_pagopa_id

select *
from pagopa_t_riconciliazione_doc doc
--where doc.pagopa_ric_doc_id=534
--where doc.pagopa_ric_doc_id=533
--where doc.pagopa_ric_doc_id=548
--where doc.pagopa_ric_doc_id=587
where doc.pagopa_ric_doc_id in
(
533,
534,
546,
547,
548,
558,
559,
560
)

select *
from pagopa_t_elaborazione_flusso flusso
where flusso.pagopa_elab_flusso_id in
(
460,
472 ,
482
)

select *
from pagopa_t_riconciliazione_doc doc
where doc.pagopa_ric_id=108
and   doc.pagopa_elab_flusso_id=496
-- 91

select *
from pagopa_t_riconciliazione_doc del
      where del.pagopa_ric_id=108
      and   del.pagopa_elab_flusso_id=496
      and   del.pagopa_ric_doc_flag_con_dett=true;

 select coalesce(count(*),0)
 from pagopa_t_riconciliazione_doc doc
 where doc.pagopa_elab_flusso_id=496
 and   doc.pagopa_ric_id!=108;

 select *
      from pagopa_t_riconciliazione_doc doc
      where doc.pagopa_elab_flusso_id=460
      and   doc.pagopa_ric_id!=80;

 select coalesce(count(*),0)
        from pagopa_t_elaborazione_flusso flusso,pagopa_r_elaborazione_file rfile
        where flusso.pagopa_elab_id=21
        and   flusso.pagopa_elab_flusso_id!=461
        and   rfile.pagopa_elab_id=flusso.pagopa_elab_id
        and   rfile.file_pagopa_id=58;

 select coalesce(count(*),0)
      from pagopa_t_elaborazione  elab,pagopa_r_elaborazione_file r
      where elab.pagopa_elab_id=371
      and   r.pagopa_elab_id=elab.pagopa_elab_id;


 select *
from pagopa_t_riconciliazione_doc doc
--where doc.pagopa_ric_doc_id=534
--where doc.pagopa_ric_doc_id=533
--where doc.pagopa_ric_doc_id=548
--where doc.pagopa_ric_doc_id=587
where doc.pagopa_ric_doc_id in
(
533,
534,
546,
547,
548,
558,
559,
560
)

select *
from pagopa_t_elaborazione_flusso flusso
where flusso.pagopa_elab_flusso_id in
(
460,
472 ,
482
)

select *
from pagopa_t_elaborazione_flusso flusso
where flusso.pagopa_elab_id=23

select *
from pagopa_r_elaborazione_file r
where r.file_pagopa_id in
(
58,
70,
80
)

select *
from pagopa_t_elaborazione flusso
where flusso.pagopa_elab_id=330

select *
from pagopa_t_elaborazione_flusso flusso
where flusso.pagopa_elab_id=330

select doc.file_pagopa_id, stato.file_pagopa_stato_code, doc.*
from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc,
     siac_t_file_pagopa file,siac_d_file_pagopa_stato stato
where flusso.pagopa_elab_id=330
and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
and   file.file_pagopa_id=doc.file_pagopa_id
and   stato.file_pagopa_stato_id=file.file_pagopa_stato_id

select r.pagopa_elab_id, doc.file_pagopa_id, stato.file_pagopa_stato_code, doc.*
from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc,
     siac_t_file_pagopa file,siac_d_file_pagopa_stato stato,pagopa_r_elaborazione_file r
where flusso.pagopa_elab_id=330
and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
and   file.file_pagopa_id=doc.file_pagopa_id
and   stato.file_pagopa_stato_id=file.file_pagopa_stato_id
and   r.file_pagopa_id=file.file_pagopa_id