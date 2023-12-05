/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- provare a invalidare l'elaborazione di file_pagopa_id=7965
-- e poi rilanciare ma prima controllare le date sul codice

select *
from siac_t_prov_cassa p
where p.provc_id=124258
-- 10086,57
select *
from siac_r_subdoc_prov_cassa r
where r.provc_id=124722
and   r.validita_fine is null
and   r.data_cancellazione is null

begin;
update siac_r_subdoc_prov_cassa r
set    data_cancellazione=now(),
       login_operazione=r.login_operazione||'-LIBERA-SIAC-7672'
where r.provc_id=124722
and   r.validita_fine is null
and   r.data_cancellazione is null

select *
from siac_r_ordinativo_prov_cassa r
where r.provc_id=124722
and   r.validita_fine is null
and   r.data_cancellazione is null

select *
from siac_t_soggetto sog
where sog.ente_proprietario_id=2
and   sog.soggetto_code='362233'

rollback;
begin;
update siac_t_soggetto sog
set    data_cancellazione=now(),
       login_operazione=sog.login_operazione||'-LIBERA-SIAC-7672'
where sog.ente_proprietario_id=2
and   sog.soggetto_code='362233'


select stato.pagopa_elab_stato_code, elab.pagopa_elab_id,
        file_stato.file_pagopa_stato_code, file.file_pagopa_id_flusso,file.file_pagopa_id
from pagopa_t_elaborazione elab,pagopa_d_elaborazione_stato stato,
     pagopa_r_elaborazione_file r,siac_t_file_pagopa file,siac_d_file_pagopa_stato file_stato
where elab.ente_proprietario_id=2
--and   elab.pagopa_elab_id= 374
and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
and   r.pagopa_elab_id=elab.pagopa_elab_id
and   file.file_pagopa_id=r.file_pagopa_id
and   file_stato.file_pagopa_stato_id=file.file_pagopa_stato_id
and   file.file_pagopa_id=7901
and   r.data_cancellazione is null
order by file.file_pagopa_id

select stato.pagopa_elab_stato_code, elab.pagopa_elab_id,
        file_stato.file_pagopa_stato_code, file.file_pagopa_id_flusso,file.file_pagopa_id,
        doc.*
from pagopa_t_elaborazione elab,pagopa_d_elaborazione_stato stato,
     pagopa_r_elaborazione_file r,siac_t_file_pagopa file,siac_d_file_pagopa_stato file_stato,
     pagopa_t_elaborazione_flusso flusso,
     pagopa_t_riconciliazione_doc doc
where elab.ente_proprietario_id=2
--and   elab.pagopa_elab_id= 374
and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
and   r.pagopa_elab_id=elab.pagopa_elab_id
and   file.file_pagopa_id=r.file_pagopa_id
and   file_stato.file_pagopa_stato_id=file.file_pagopa_stato_id
and   file.file_pagopa_id=7901
and   flusso.pagopa_elab_id=elab.pagopa_elab_id
and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
and   doc.pagopa_ric_id=8673
and   r.data_cancellazione is null
order by file.file_pagopa_id

select *
from pagopa_t_riconciliazione ric
where ric.file_pagopa_id=7901

-- 8777,8778,8779
select *
from pagopa_t_riconciliazione_doc ric
where ric.file_pagopa_id=7901
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
and   doc.pagopa_ric_id=8673
and   file.file_pagopa_id in  (7901)
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

-- 7971, 7970, 7969,  --  elab  380 annullata

-- 7692 -- 63 rec -- elab 373 che dovrebbe essere cancellata