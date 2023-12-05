/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- nuove colonne x mif_d_flusso_elaborato
SELECT * from fnc_dba_add_column_params ('mif_t_ordinativo_spesa', 'mif_ord_pagopa_num_avviso', 'varchar(50)');
SELECT * from fnc_dba_add_column_params ('mif_t_ordinativo_spesa', 'mif_ord_pagopa_codfisc', 'varchar(16)');

-- inserimento nuovi tag su mif_d_flusso_elaborato
INSERT INTO mif_d_flusso_elaborato
(
      flusso_elab_mif_ordine,
      flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
      flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
      flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
      validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
      flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id
)
select 150,'avviso_pagoPA','avviso_pagoPA',true,
       'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.informazioni_aggiuntive','',NULL,NULL,true,
       'AVVISO PAGOPA','2019-01-01',ente.ente_proprietario_id,'SIAC-6840',136,NULL,true,tipo.flusso_elab_mif_tipo_id
from siac_t_ente_proprietario ente,  mif_d_flusso_elaborato_tipo tipo
where  ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and    tipo.ente_proprietario_id=ente.ente_proprietario_id
and    tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and    not exists
(
select 1 from mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=ente.ente_proprietario_id
and mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and mif.flusso_elab_mif_ordine=150
and mif.flusso_elab_mif_code='avviso_pagoPA'
);

INSERT INTO mif_d_flusso_elaborato
(
      flusso_elab_mif_ordine,
      flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
      flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
      flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
      validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
      flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id
)
select 151,'codice_identificativo_ente','Codice fiscale soggetto intestatario mandato',true,
       'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.informazioni_aggiuntive.avviso_pagoPA',
       'mif_t_ordinativo_spesa','mif_ord_pagopa_codfisc','',true,'','2019-01-01',
       ente.ente_proprietario_id,'SIAC-6840',137,NULL,true,tipo.flusso_elab_mif_tipo_id
from siac_t_ente_proprietario ente,  mif_d_flusso_elaborato_tipo tipo
where  ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and    tipo.ente_proprietario_id=ente.ente_proprietario_id
and    tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and    not exists
(
select 1 from mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=ente.ente_proprietario_id
and mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and mif.flusso_elab_mif_ordine=151
and mif.flusso_elab_mif_code='codice_identificativo_ente'
);

INSERT INTO mif_d_flusso_elaborato
(
      flusso_elab_mif_ordine,
      flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
      flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
      flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
      validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
      flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id
)
select 152,'numero_avviso','Numero avviso',true,
       'flusso_ordinativi.ordinativi.mandato.informazioni_beneficiario.informazioni_aggiuntive.avviso_pagoPA',
       'mif_t_ordinativo_spesa','mif_ord_pagopa_num_avviso',NULL,true,NULL,'2019-01-01',
       ente.ente_proprietario_id,'SIAC-6840',138,NULL,true,tipo.flusso_elab_mif_tipo_id
from siac_t_ente_proprietario ente,  mif_d_flusso_elaborato_tipo tipo
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and   not exists
(
select 1 from mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=ente.ente_proprietario_id
and mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and mif.flusso_elab_mif_ordine=152
and mif.flusso_elab_mif_code='numero_avviso'
);

-- spostamento tag
update  mif_d_flusso_elaborato mif
set     flusso_elab_mif_ordine=mif.flusso_elab_mif_ordine+3
from    siac_t_ente_proprietario ente
where  ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and    mif.ente_proprietario_id=ente.ente_proprietario_id
and    mif.flusso_elab_mif_ordine>=150
and    mif.flusso_elab_mif_code !='avviso_pagoPA'
and    mif.flusso_elab_mif_code_padre not like '%avviso_pagoPA%'
and    exists
(
select 1
from mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
)
and exists
(
select 1
from mif_d_flusso_elaborato mif1,mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and   mif1.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif1.flusso_elab_mif_ordine=150
and   mif1.flusso_elab_mif_code !='avviso_pagoPA'
)
and not exists
(
select 1
from mif_d_flusso_elaborato mif1,mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and   mif1.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
--and   mif1.flusso_elab_mif_ordine=150
and   mif1.flusso_elab_mif_code ='avviso_pagoPA'
);

-- inserimento nuova modalita di accredito
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
from siac_t_ente_proprietario ente,siac_d_accredito_gruppo gruppo
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   gruppo.ente_proprietario_id=ente.ente_proprietario_id
and   gruppo.accredito_gruppo_code='GE'
and   not exists
(
select 1
from siac_d_accredito_tipo accre
where accre.ente_proprietario_id=ente.ente_proprietario_id
and   accre.accredito_gruppo_id=gruppo.accredito_gruppo_id
and   accre.accredito_tipo_code='APA'
and   accre.accredito_tipo_desc='AVVISO PAGOPA'
and   accre.data_cancellazione is null
and   accre.validita_fine is null
);

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
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   not exists
(
select 1
from siac_d_accredito_tipo_oil oil
where oil.ente_proprietario_id=ente.ente_proprietario_id
and   oil.accredito_tipo_oil_code='22'
and   oil.accredito_tipo_oil_desc='AVVISO PAGOPA'
and   oil.data_cancellazione is null
and   oil.validita_fine is null
);


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
where ente.ente_proprietario_id in (2,3,4,5,10,13,14,16)
and   tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.accredito_tipo_code='APA'
and   tipo.accredito_tipo_desc='AVVISO PAGOPA'
and   oil.ente_proprietario_id=ente.ente_proprietario_id
and   oil.accredito_tipo_oil_code='22'
and   oil.accredito_tipo_oil_desc='AVVISO PAGOPA'
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
and   oil.data_cancellazione is null
and   oil.validita_fine is null
and   not exists
(
select 1
from siac_r_accredito_tipo_oil r
where r.ente_proprietario_id=ente.ente_proprietario_id
and   r.accredito_tipo_id=tipo.accredito_tipo_id
and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
and   r.data_cancellazione is null
and   r.validita_fine is null
);