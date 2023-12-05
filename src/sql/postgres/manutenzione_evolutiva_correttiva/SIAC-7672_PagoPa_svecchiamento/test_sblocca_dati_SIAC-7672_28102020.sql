/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿select pagopa.file_pagopa_id
    from siac_t_file_pagopa pagopa, siac_d_file_pagopa_stato stato
    where stato.ente_proprietario_id=2
    and   stato.file_pagopa_stato_code in ('ACQUISITO','ELABORATO_IN_CORSO','ELABORATO_IN_CORSO_SC','ELABORATO_IN_CORSO_ER')
    and   pagopa.file_pagopa_stato_id=stato.file_pagopa_stato_id
    and   pagopa.file_pagopa_anno in (2020,2019)
    and   pagopa.data_cancellazione is null
    and   pagopa.validita_fine is null;

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
and   doc.pagopa_ric_id in (8377,8378)
--and   elab.pagopa_elab_id=373
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


select stato.pagopa_elab_stato_code, elab.*
from pagopa_t_elaborazione elab,pagopa_d_elaborazione_stato stato
where elab.ente_proprietario_id=2
and   elab.pagopa_elab_id= 373
and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id


select stato.pagopa_elab_stato_code, elab.pagopa_elab_id,
        file_stato.file_pagopa_stato_code, file.file_pagopa_id_flusso,file.file_pagopa_id
from pagopa_t_elaborazione elab,pagopa_d_elaborazione_stato stato,
     pagopa_r_elaborazione_file r,siac_t_file_pagopa file,siac_d_file_pagopa_stato file_stato
where elab.ente_proprietario_id=2
and   elab.pagopa_elab_id= 374
and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
and   r.pagopa_elab_id=elab.pagopa_elab_id
and   file.file_pagopa_id=r.file_pagopa_id
and   file_stato.file_pagopa_stato_id=file.file_pagopa_stato_id
and   r.data_cancellazione is null
order by file.file_pagopa_id


select stato.pagopa_elab_stato_code, elab.pagopa_elab_id,
        file_stato.file_pagopa_stato_code, file.file_pagopa_id_flusso,file.file_pagopa_id,
        ric.*
from pagopa_t_elaborazione elab,pagopa_d_elaborazione_stato stato,
     pagopa_r_elaborazione_file r,siac_t_file_pagopa file,siac_d_file_pagopa_stato file_stato,
     pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc,
     pagopa_t_riconciliazione ric
where elab.ente_proprietario_id=2
and   elab.pagopa_elab_id= 374
and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
and   r.pagopa_elab_id=elab.pagopa_elab_id
and   file.file_pagopa_id=r.file_pagopa_id
and   file_stato.file_pagopa_stato_id=file.file_pagopa_stato_id
and   flusso.pagopa_elab_id=elab.pagopa_elab_id
and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
and   doc.file_pagopa_id=file.file_pagopa_id
and   ric.pagopa_ric_id=doc.pagopa_ric_id
--and   r.data_cancellazione is null
order by file.file_pagopa_id

rollback;
begin;
update pagopa_t_riconciliazione ric
set    pagopa_ric_flusso_stato_elab='N',
       login_operazione=ric.login_operazione||'-LIBERA-SIAC-7672'
from pagopa_t_elaborazione elab,pagopa_d_elaborazione_stato stato,
     pagopa_r_elaborazione_file r,siac_t_file_pagopa file,siac_d_file_pagopa_stato file_stato,
     pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
where elab.ente_proprietario_id=2
and   elab.pagopa_elab_id= 376
and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
and   r.pagopa_elab_id=elab.pagopa_elab_id
and   file.file_pagopa_id=r.file_pagopa_id
and   file_stato.file_pagopa_stato_id=file.file_pagopa_stato_id
and   flusso.pagopa_elab_id=elab.pagopa_elab_id
and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
and   doc.file_pagopa_id=file.file_pagopa_id
and   ric.pagopa_ric_id=doc.pagopa_ric_id
and   file.file_pagopa_id=7901
and   doc.pagopa_ric_id=8673
and   r.data_cancellazione is null

select *
from pagopa_t_riconciliazione ric
where ric.ente_proprietario_id=2
and   ric.login_operazione like '%LIBERA-SIAC-7672'

select *
from pagopa_t_riconciliazione_Doc ric
where ric.ente_proprietario_id=2
and   ric.login_operazione like '%LIBERA-SIAC-7672'

begin;
update pagopa_t_riconciliazione_doc doc
set    data_cancellazione=now(),
       login_operazione=doc.login_operazione||'-LIBERA-SIAC-7672'
from pagopa_t_elaborazione elab,pagopa_d_elaborazione_stato stato,
     pagopa_r_elaborazione_file r,siac_t_file_pagopa file,siac_d_file_pagopa_stato file_stato,
     pagopa_t_elaborazione_flusso flusso
where elab.ente_proprietario_id=2
and   elab.pagopa_elab_id= 376
and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
and   r.pagopa_elab_id=elab.pagopa_elab_id
and   file.file_pagopa_id=r.file_pagopa_id
and   file_stato.file_pagopa_stato_id=file.file_pagopa_stato_id
and   flusso.pagopa_elab_id=elab.pagopa_elab_id
and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
and   doc.file_pagopa_id=file.file_pagopa_id
and   file.file_pagopa_id=7901
and   doc.pagopa_ric_id=8673

and   r.data_cancellazione is null

select *
from siac_d_file_pagopa_stato statoNew

select *
from pagopa_d_elaborazione_stato statoNew

rollback;
begin;
update siac_t_file_pagopa file
set   file_pagopa_stato_id=statoNew.file_pagopa_stato_id,
      login_operazione=file.login_operazione||'-LIBERA-SIAC-7672',
      data_cancellazione=null, validita_fine=null
from pagopa_t_elaborazione elab,pagopa_d_elaborazione_stato stato,
     pagopa_r_elaborazione_file r,siac_d_file_pagopa_stato file_stato,
     siac_d_file_pagopa_stato statoNew
where elab.ente_proprietario_id=2
and   elab.pagopa_elab_id= 376
and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
and   r.pagopa_elab_id=elab.pagopa_elab_id
and   file.file_pagopa_id=r.file_pagopa_id
and   file_stato.file_pagopa_stato_id=file.file_pagopa_stato_id
and   statoNew.ente_proprietario_id=2
and   statoNew.file_pagopa_stato_code='ELABORATO_IN_CORSO_SC'
and   file.file_pagopa_id=7901

and   r.data_cancellazione is null

update pagopa_r_elaborazione_file r
set    data_cancellazione=now(),
       login_operazione=r.login_operazione||'-LIBERA-SIAC-7672'
from pagopa_t_elaborazione elab,pagopa_d_elaborazione_stato stato
where elab.ente_proprietario_id=2
and   elab.pagopa_elab_id= 376
and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
and   r.pagopa_elab_id=elab.pagopa_elab_id
and   r.file_pagopa_id=7901

and   r.data_cancellazione is null

update pagopa_t_elaborazione elab
set    data_cancellazione=now(),
       pagopa_elab_stato_id=statoNew.pagopa_elab_stato_id,
       login_operazione=elab.login_operazione||'-LIBERA-SIAC-7672'
from pagopa_d_elaborazione_stato stato,pagopa_d_elaborazione_stato statoNew
where elab.ente_proprietario_id=2
and   elab.pagopa_elab_id= 378
and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
and   statoNew.ente_proprietario_id=2
and   statoNew.pagopa_elab_stato_code='ANNULLATO'