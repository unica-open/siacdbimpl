/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


SELECT * FROM  fnc_dba_add_column_params ( 'mif_t_ordinativo_spesa_documenti', 'mif_ord_doc_ut_nota_credito', 'VARCHAR(100)');

begin;
update mif_d_flusso_elaborato mif
set    flusso_elab_mif_ordine=mif.flusso_elab_mif_ordine+1,
       data_modifica=now(),
       login_operazione=mif.login_operazione||'-SIAC-7448'
from mif_d_flusso_elaborato_tipo tipo,siac_t_ente_proprietario ente
where ente.ente_proprietario_id=2
and   tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif.flusso_elab_mif_ordine>=59
and   not exists
(
select 1
from mif_d_flusso_elaborato mif1
where mif1.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
and   mif1.flusso_elab_mif_code='utilizzo_nota_di_credito'
);


update mif_d_flusso_elaborato mif
set    flusso_elab_mif_param=mif.flusso_elab_mif_param||'|FSN',
       data_modifica=now(),
       login_operazione=mif.login_operazione||'-SIAC-7448'
from mif_d_flusso_elaborato_tipo tipo,siac_t_ente_proprietario ente
where ente.ente_proprietario_id=2
and   tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif.flusso_elab_mif_code='tipo_debito_siope_c'
and   not exists
(
select 1
from mif_d_flusso_elaborato mif1
where mif1.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
and   mif1.flusso_elab_mif_code='utilizzo_nota_di_credito'
);


update mif_d_flusso_elaborato mif
set    flusso_elab_mif_param='ELETTRONICO',
       data_modifica=now(),
       login_operazione=mif.login_operazione||'-SIAC-7448'
from mif_d_flusso_elaborato_tipo tipo,siac_t_ente_proprietario ente
where ente.ente_proprietario_id=2
and   tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif.flusso_elab_mif_code='tipo_documento_siope_e'
and   not exists
(
select 1
from mif_d_flusso_elaborato mif1
where mif1.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
and   mif1.flusso_elab_mif_code='utilizzo_nota_di_credito'
);


insert into mif_d_flusso_elaborato
(
  flusso_elab_mif_tipo_id,
  flusso_elab_mif_ordine,
  flusso_elab_mif_ordine_elab,
  flusso_elab_mif_code,
  flusso_elab_mif_desc,
  flusso_elab_mif_attivo,
  flusso_elab_mif_xml_out,
  flusso_elab_mif_code_padre,
  flusso_elab_mif_tabella,
  flusso_elab_mif_campo,
  flusso_elab_mif_default,
  flusso_elab_mif_elab,
  flusso_elab_mif_param,
  flusso_elab_mif_query,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select
  tipo.flusso_elab_mif_tipo_id,
  59,--flusso_elab_mif_ordine,
  74,--flusso_elab_mif_ordine_elab,
  'utilizzo_nota_di_credito',--flusso_elab_mif_code,
  'Tipo di utilizzo della nota di credito',--flusso_elab_mif_desc,
  true,--flusso_elab_mif_attivo,
  true,--flusso_elab_mif_xml_out,
  'flusso_ordinativi.ordinativi.reversale.informazioni_versante.classificazione.classificazione_dati_siope_entrate.fatture_siope.fattura_siope.dati_fattura_siope',--flusso_elab_mif_code_padre,
  'mif_t_ordinativo_spesa_documenti',--flusso_elab_mif_tabella,
  'mif_ord_doc_ut_nota_credito',--flusso_elab_mif_campo,
  'SPLIT PAYMENT|INCASSO/COMPENSAZIONE',--flusso_elab_mif_default,
  true,  --flusso_elab_mif_elab,
  'FSN|CORRENTE',    --flusso_elab_mif_param,
  null,  --flusso_elab_mif_query,
  now(),
  'SIAC-7448',
  ente.ente_proprietario_id
from mif_d_flusso_elaborato_tipo tipo,siac_t_ente_proprietario ente
where ente.ente_proprietario_id=2
and   tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS'
and   not exists
(
select 1
from mif_d_flusso_elaborato mif1
where mif1.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif1.flusso_elab_mif_code='utilizzo_nota_di_credito'
);
