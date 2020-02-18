/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
alter table siac_d_oil_qualificatore add oil_qualificatore_dr_rec boolean default false;

select tipo.oil_ricevuta_tipo_code, q.*, d.*
from siac_d_oil_qualificatore  q, siac_d_oil_ricevuta_tipo tipo, siac_d_oil_esito_derivato d
where q.ente_proprietario_id=4
and   q.oil_esito_derivato_id=d.oil_esito_derivato_id
and   tipo.oil_ricevuta_tipo_id=d.oil_ricevuta_tipo_id
and   tipo.oil_ricevuta_tipo_code in ('Q','S')
--and   q.oil_qualificatore_code not in ('SRR','SRM')

-- update da fare per tutti gli enti
begin;
update siac_d_oil_qualificatore q
set oil_qualificatore_dr_rec=true
from  siac_d_oil_ricevuta_tipo tipo, siac_d_oil_esito_derivato d
where q.ente_proprietario_id=4
and   q.oil_esito_derivato_id=d.oil_esito_derivato_id
and   tipo.oil_ricevuta_tipo_id=d.oil_ricevuta_tipo_id
and   tipo.oil_ricevuta_tipo_code in ('Q','S')
and   q.oil_qualificatore_code not in ('SRR','SRM')

-- 20.05.2016 Sofia - siac-3435
update siac_d_oil_qualificatore q
set oil_qualificatore_dr_rec=true
from  siac_d_oil_ricevuta_tipo tipo, siac_d_oil_esito_derivato d
where q.oil_qualificatore_code not in ('SRR','SRM')
and   q.oil_esito_derivato_id=d.oil_esito_derivato_id
and   tipo.oil_ricevuta_tipo_id=d.oil_ricevuta_tipo_id
and   tipo.oil_ricevuta_tipo_code in ('Q','S')

select q.ente_proprietario_id,q.oil_qualificatore_code, q.oil_qualificatore_dr_rec
from  siac_d_oil_ricevuta_tipo tipo, siac_d_oil_esito_derivato d, siac_d_oil_qualificatore q
where q.oil_qualificatore_code not in ('SRR','SRM')
and   q.oil_esito_derivato_id=d.oil_esito_derivato_id
and   tipo.oil_ricevuta_tipo_id=d.oil_ricevuta_tipo_id
and   tipo.oil_ricevuta_tipo_code in ('Q','S')
order by 1,2
-- 30 righe