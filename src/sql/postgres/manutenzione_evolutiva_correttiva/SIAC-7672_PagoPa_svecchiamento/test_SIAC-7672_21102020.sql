/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


select stato.pagopa_elab_stato_code , elab.pagopa_elab_id, elab.pagopa_elab_note,
       stato_file.file_pagopa_stato_code,file.file_pagopa_id, file.file_pagopa_id_flusso
from pagopa_t_elaborazione elab, pagopa_d_elaborazione_stato stato,
     pagopa_r_elaborazione_file r, siac_t_file_pagopa file, siac_d_file_pagopa_stato stato_file
where stato.ente_proprietario_id=2
and   elab.pagopa_elab_stato_id=stato.pagopa_elab_stato_id
and   r.pagopa_elab_id=elab.pagopa_elab_id
and   file.file_pagopa_id=r.file_pagopa_id
and   stato_file.file_pagopa_stato_id=file.file_pagopa_stato_id
and   r.data_cancellazione is null
and   r.validita_fine is null
order by elab.pagopa_elab_id desc, file.file_pagopa_id

-- se elaborazione_KO  o ERRATO, SCARTATO
-- per ogni record così trovato
-- cercare
-- per lo stesso pagopa_t_riconciliazione
-- precedenti elaborazioni in errore ( stesse condizioni )
-- se trovate procedere con la cancellazione dei dati di elaborazione
-- sino  a cancellare tutti i dati coinvolti in elaborazione se non esiste altro sotto
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
and   r.data_cancellazione is null
and   r.validita_fine is null
and   doc.data_cancellazione is null
and   elab.data_cancellazione is null
and   flusso.data_cancellazione is null
and   file.data_cancellazione is null
order by elab.pagopa_elab_id desc, file.file_pagopa_id,doc.pagopa_ric_id

