/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿

select --sum(a.fnc_durata)
 a.*
from siac_dwh_log_elaborazioni a
where a.ente_proprietario_id=2
and   a.fnc_name like '%doc%spesa%'
order by a.log_id desc

select *
from siac_d_gestione_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.gestione_tipo_code='ANNO_STORICO_DWH_DOC_SPESA_ATTIVO'


select *
from siac_d_gestione_livello liv
where liv.ente_proprietario_id=2
and   liv.gestione_livello_code like '%ANNO_STORICO_DWH_DOC_SPESA_ATTIVO'


  insert into siac_d_gestione_livello
  (
  	gestione_livello_code,
    gestione_livello_desc,
    gestione_tipo_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  select
	'2019_'||tipo.gestione_tipo_code,
    tipo.gestione_tipo_desc,
    tipo.gestione_tipo_id,
    now(),
    tipo.login_operazione,
    tipo.ente_proprietario_id
  from siac_d_gestione_tipo tipo,siac_t_ente_proprietario ente
  where ente.ente_Proprietario_id in (2,3,4,5,10,14,16)
  and   tipo.ente_proprietario_id=ente.ente_proprietario_id
  and   tipo.gestione_tipo_code='ANNO_STORICO_DWH_DOC_SPESA_ATTIVO'
  and   not exists
  (
  select 1
  from siac_d_gestione_livello liv
  where liv.ente_proprietario_id=ente.ente_proprietario_id
  and   liv.gestione_tipo_id=tipo.gestione_tipo_id
  and   liv.gestione_livello_code='2019_'||tipo.gestione_tipo_code
  );

select *
from siac_d_gestione_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.gestione_tipo_code='CARICA_STORICO_DWH_DOC_SPESA_ATTIVO'

select *
from siac_d_gestione_livello liv
where liv.ente_proprietario_id=2
and   liv.gestione_livello_code = 'CARICA_STORICO_DWH_DOC_SPESA_ATTIVO'



select *
from siac_d_gestione_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.gestione_tipo_code='ELABORA_STORICO_DWH_DOC_SPESA_ATTIVO'

select *
from siac_d_gestione_livello liv
where liv.ente_proprietario_id=2
and   liv.gestione_livello_code = 'ELABORA_STORICO_DWH_DOC_SPESA_ATTIVO'


select count(*)
from siac_dwh_documento_spesa d
where d.ente_proprietario_id=2
-- 258029
-- 252287
-- 258103
-- 259202
select *
from siac_dwh_documento_spesa d
where d.ente_proprietario_id=2


select count(*)
from siac_dwh_st_documento_spesa d
where d.ente_proprietario_id=2
--112622
-- 118438
-- 176249

begin;
select
fnc_siac_dwh_documento_spesa
(
  2,
  null
);

select
fnc_siac_dwh_st_documento_spesa
(
   2,
  null
)