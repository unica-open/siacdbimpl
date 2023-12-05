/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--- 31.10.2022 Sofia 
--    trattamento dati per svecchiamento 2019/2020
--  SIAC-8161_TD_x_svecchiamenti_31102022.sql
-- 04.11.2022 Sofia - eseguito in prod 
-- svecchiamento 2019 - post elaborazione 

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
