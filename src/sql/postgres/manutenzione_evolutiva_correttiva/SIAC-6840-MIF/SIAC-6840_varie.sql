/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
select mif.*
from mif_d_flusso_elaborato mif
where  mif.ente_proprietario_id=2
and   exists
(
select 1
from mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
)
order by mif.flusso_elab_mif_ordine

begin;
update  mif_d_flusso_elaborato mif
set     flusso_elab_mif_ordine=mif.flusso_elab_mif_ordine+3
where  mif.ente_proprietario_id=2
and   exists
(
select 1
from mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
)
and  mif.flusso_elab_mif_ordine>=150
and  mif.flusso_elab_mif_code !='avviso_pagoPA'
and  mif.flusso_elab_mif_code_padre not like '%avviso_pagoPA%'


-- mif_ord_pagopa_codfisc
-- mif_ord_pagopa_num_avviso

alter table mif_t_ordinativo_spesa
      add mif_ord_pagopa_num_avviso varchar(50),
      add mif_ord_pagopa_codfisc varchar(16)

select *
from siac_d_accredito_tipo tipo
where tipo.ente_proprietario_id=2

select *
from siac_d_accredito_tipo_oil oil
where oil.ente_proprietario_id=2
and   oil.data_cancellazione is null


select *
from siac_r_accredito_tipo_oil r
where r.ente_proprietario_id=2
and   r.data_cancellazione is null


rollback;
begin;
insert into siac_d_accredito_tipo
(
  accredito_tipo_code,
  accredito_tipo_desc,
  accredito_priorita,
  accredito_gruppo_id,
  login_operazione,
  ente_proprietario_id,
  validita_inizio
)
select 'APA',
       'AVVISO PAGOPA',
       0,
       gruppo.accredito_gruppo_id,
       'SIAC-6840',
       gruppo.ente_proprietario_id,
       now()
from siac_d_accredito_gruppo gruppo
where gruppo.ente_proprietario_id=2
and   gruppo.accredito_gruppo_code='GE'

insert into siac_d_accredito_tipo_oil
(
  accredito_tipo_oil_code,
  accredito_tipo_oil_desc,
  login_operazione,
  ente_proprietario_id,
  validita_inizio
)
select '22',
       'AVVISO PAGOPA',
       'SIAC-6840',
       ente.ente_proprietario_id,
       now()
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id=2


insert into siac_r_accredito_tipo_oil
(
  accredito_tipo_id,
  accredito_tipo_oil_id,
  login_operazione,
  ente_proprietario_id,
  validita_inizio
)
select tipo.accredito_tipo_id,
       oil.accredito_tipo_oil_id,
        'SIAC-6840',
       ente.ente_proprietario_id,
       now()
from siac_t_ente_proprietario ente,
     siac_d_accredito_tipo tipo,
     siac_d_accredito_tipo_oil oil
where ente.ente_proprietario_id=2
and   tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.accredito_tipo_code='APA'
and   oil.ente_proprietario_id=ente.ente_proprietario_id
and   oil.accredito_tipo_oil_desc='AVVISO PAGOPA'

--------------------------------------------


select *
from siac_v_bko_ordinativo_op_valido op
where op.ente_proprietario_id=2
and   op.anno_bilancio=2019
and   op.ord_numero=154
order by op.ord_numero desc


select tipo.*
from siac_v_bko_ordinativo_op_valido op,siac_r_ordinativo_modpag r,siac_t_modpag mdp,
     siac_d_accredito_tipo tipo
where op.ente_proprietario_id=2
and   op.anno_bilancio=2019
and   op.ord_numero=154
and   r.ord_id=op.ord_id
and   mdp.modpag_id=r.modpag_id
and   tipo.accredito_tipo_id=mdp.accredito_tipo_id
and   r.data_cancellazione is null
and   r.validita_fine is null
order by op.ord_numero desc



select tipo.doc_tipo_code, doc.*
from siac_v_bko_ordinativo_op_valido op,siac_t_ordinativo_ts ts,siac_r_subdoc_ordinativo_ts rsub,
     siac_t_subdoc sub,siac_t_doc doc ,siac_d_doc_tipo tipo
where op.ente_proprietario_id=2
and   op.anno_bilancio=2019
and   op.ord_numero=154
and   ts.ord_id=op.ord_id
and   rsub.ord_ts_id=ts.ord_ts_id
and   sub.subdoc_id=rsub.subdoc_id
and   doc.doc_id=sub.doc_id
and   tipo.doc_tipo_id=doc.doc_tipo_id
and   rsub.data_cancellazione is null
and   rsub.validita_fine is null
order by op.ord_numero desc

begin;
update siac_r_ordinativo_modpag r
set    data_cancellazione=now(),
       validita_fine=now(),
       login_operazione=r.login_operazione||'-SIAC-6840'
from siac_v_bko_ordinativo_op_valido op,siac_t_modpag mdp
where op.ente_proprietario_id=2
and   op.anno_bilancio=2019
and   op.ord_numero=154
and   r.ord_id=op.ord_id
and   mdp.modpag_id=r.modpag_id
and   r.login_operazione!='SIAC-6840'
and   r.data_cancellazione is null
and   r.validita_fine is null

begin;
insert into siac_r_ordinativo_modpag
(
	ord_id,
    modpag_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select op.ord_id,
       mdp.modpag_id,
       now(),
       'SIAC-6840',
       mdp.ente_proprietario_id
from siac_v_bko_ordinativo_op_valido op, siac_r_ordinativo_soggetto r,siac_t_modpag mdp,
     siac_d_accredito_tipo tipo
where op.ente_proprietario_id=2
and   op.anno_bilancio=2019
and   op.ord_numero=154
and   r.ord_id=op.ord_id
and   mdp.soggetto_id=r.soggetto_id
and   tipo.accredito_tipo_id=mdp.accredito_tipo_id
and   tipo.accredito_tipo_code='APA'
and   r.data_cancellazione is null
and   r.validita_fine is null

begin;
update siac_t_doc doc
set    cod_avviso_pago_pa='ZZZZZZZZZZZ'
from siac_v_bko_ordinativo_op_valido op,siac_t_ordinativo_ts ts,siac_r_subdoc_ordinativo_ts rsub,
     siac_t_subdoc sub,siac_d_doc_tipo tipo
where op.ente_proprietario_id=2
and   op.anno_bilancio=2019
and   op.ord_numero=154
and   ts.ord_id=op.ord_id
and   rsub.ord_ts_id=ts.ord_ts_id
and   sub.subdoc_id=rsub.subdoc_id
and   doc.doc_id=sub.doc_id
and   tipo.doc_tipo_id=doc.doc_tipo_id
and   rsub.data_cancellazione is null
and   rsub.validita_fine is null


select mif.mif_ord_codfisc_benef,mif.mif_ord_partiva_benef, mif.mif_ord_partiva_del, mif.mif_ord_codfisc_del,*
from mif_t_ordinativo_spesa mif
where mif.ente_proprietario_id=2
and   mif.mif_ord_anno_esercizio::integer=2019
and   mif.mif_ord_numero::integer=154

select mif.mif_ord_codfisc_del,*
from mif_t_flusso_elaborato mif
where mif.ente_proprietario_id=2
order by mif.flusso_elab_mif_id desc

select *
from mif_t_ordinativo_spesa_id





select 'INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) select '
            ||  d.flusso_elab_mif_ordine||','
            ||  quote_nullable(d.flusso_elab_mif_code)||','
            ||  quote_nullable(d.flusso_elab_mif_desc)||','
            ||  d.flusso_elab_mif_attivo||','
            ||  quote_nullable(d.flusso_elab_mif_code_padre)||','
            ||  quote_nullable(d.flusso_elab_mif_tabella)||','
            ||  quote_nullable(d.flusso_elab_mif_campo)||','
            ||  quote_nullable(d.flusso_elab_mif_default)||','
            ||  d.flusso_elab_mif_elab||','
            ||  quote_nullable(d.flusso_elab_mif_param)||','
            ||  quote_nullable('2019-01-01')||','
            ||  'ente.ente_proprietario_id'||','
            ||  quote_nullable('SIAC-6840')||','
            ||  d.flusso_elab_mif_ordine_elab||','
            ||  quote_nullable(d.flusso_elab_mif_query)||','
            ||  d.flusso_elab_mif_xml_out||','
            ||  'tipo.flusso_elab_mif_tipo_id '
            ||  ' from siac_t_ente_proprietario ente,  mif_d_flusso_elaborato_tipo tipo where '
            ||  ' tipo.ente_proprietario_id=ente.ente_proprietario_id '
            ||  ' and tipo.flusso_elab_mif_tipo_code=''MANDMIF_SPLUS'' '
            ||  ' and not exists ( select 1 from mif_d_flusso_elaborato mif where mif.ente_proprietario_id=ente.ente_proprietario_id '
            ||  ' and mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id '
            ||  ' and mif.flusso_elab_mif_ordine='||d.flusso_elab_mif_ordine
            ||  ' and mif.flusso_elab_mif_code='||quote_nullable(d.flusso_elab_mif_code)
            ||  ');'
from mif_d_flusso_elaborato d,
     mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=2
and   d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   d.flusso_elab_mif_ordine in (150,151,152)
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
order by d.flusso_elab_mif_ordine

