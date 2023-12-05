/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
insert into pagopa_d_riconciliazione_errore
(
	pagopa_ric_errore_code,
    pagopa_ric_errore_desc,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select '51',
       'DATI RICONCILIAZIONE CON ACCERTAMENTO PRIVO DI SOGGETTO O INESISTENTE',
       now(),
       'SIAC-6963',
       ente.ente_proprietario_id
from siac_t_ente_proprietario ente
WHERE not exists
(select 1
 from pagopa_d_riconciliazione_errore errore
 where errore.ente_proprietario_id=ente.ente_proprietario_id
 and   errore.pagopa_ric_errore_code='51'
 and   errore.data_cancellazione is null
 );
 
insert into siac_t_attr
(
 attr_code,
 attr_desc,
 attr_tipo_id,
 validita_inizio,
 login_operazione,
 ente_proprietario_id
)
select 'flagSenzaNumero',
       'flagSenzaNumero',
       tipo.attr_tipo_id,
       now(),
       'SIAC-6963',
       ente.ente_proprietario_id
from siac_t_ente_proprietario ente , siac_d_attr_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.attr_tipo_code='B'
and   not exists
(
select 1
from siac_t_attr attr
where attr.ente_proprietario_id=ente.ente_proprietario_id
and   attr.attr_tipo_id=tipo.attr_tipo_id
and   attr.attr_code='flagSenzaNumero'
and   attr.data_cancellazione is null
);


insert into siac_r_doc_tipo_attr
(
	doc_tipo_id,
    attr_id,
    boolean,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select tipo.doc_tipo_id,
       attr.attr_id,
       'S',
       now(),
       'SIAC-6963',
       attr.ente_proprietario_id
from siac_t_ente_proprietario ente, siac_t_attr attr,   siac_d_doc_tipo tipo,siac_d_doc_fam_tipo fam
where attr.ente_proprietario_id=ente.ente_proprietario_id
and   attr.attr_code='flagSenzaNumero'
and   tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.doc_tipo_code in ('COR','FTV')
and   fam.doc_fam_tipo_id=tipo.doc_fam_tipo_id
and   fam.doc_fam_tipo_code='E'
and   not exists
(select 1
 from  siac_r_doc_tipo_attr r
 where r.ente_proprietario_id=ente.ente_proprietario_id
 and   r.doc_tipo_id=tipo.doc_tipo_id
 and   r.attr_id=attr.attr_id
 and   r.data_cancellazione is null
);