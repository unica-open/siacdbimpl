/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿ select r.*
  from siac_r_ordinativo_stato r, siac_d_ordinativo_stato stato
  where stato.ente_proprietario_id=2
  and   stato.ord_stato_code='Q'
  and   r.ord_stato_id=stato.ord_stato_id
  and   not EXISTS
  (select 1
  from siac_r_ordinativo_stato r1
  where r1.ord_id=r.ord_id
  and   r1.ord_stato_id!=r.ord_stato_id
  and  r1.data_cancellazione is null
  and   r1.validita_fine is not null
  )
  and   r.data_cancellazione is null
  and   r.validita_fine is not null




  select anno.anno_bilancio,
  tipo.ord_tipo_code,
         ord.ord_numero::integer,
         ord.ord_id,
         stato.ord_stato_code,
         rs.validita_inizio, rs.validita_fine,
         rs.login_operazione
from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo, siac_v_bko_anno_bilancio anno,
     siac_r_ordinativo_stato rs, siac_d_ordinativo_stato stato
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   anno.bil_id=ord.bil_id
and   anno.anno_bilancio=2017
and   ord.ord_numero in (13940,13941,13942)
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   rs.data_cancellazione is null
order by ord.ord_numero::integer,rs.validita_inizio, rs.validita_fine

-- 13940
-- 13941
-- 13942

  select anno.anno_bilancio,
  tipo.ord_tipo_code,
         ord.ord_numero::integer,
         ord.ord_id,
         stato.ord_stato_code,
         rs.validita_inizio, rs.validita_fine,
         rs.login_operazione,
         ord.ord_id
        -- r.*
from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo, siac_v_bko_anno_bilancio anno,
     siac_r_ordinativo_stato rs, siac_d_ordinativo_stato stato--,siac_r_ordinativo_firma r
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   anno.bil_id=ord.bil_id
and   anno.anno_bilancio=2017
and   ord.ord_numero in (13940,13941,13942)
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   rs.data_cancellazione is null
--and   r.ord_id=ord.ord_id
order by ord.ord_numero::integer,rs.validita_inizio, rs.validita_fine

select *
from siac_r_ordinativo_firma r
where r.ord_id=20849

rollback;
begin;
update siac_r_ordinativo_stato rs
set    validita_fine=now()
from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo, siac_v_bko_anno_bilancio anno,
      siac_d_ordinativo_stato stato,siac_r_ordinativo_firma r
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   anno.bil_id=ord.bil_id
and   anno.anno_bilancio=2017
and   ord.ord_numero in (13940,13941,13942)
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   stato.ord_stato_code='F'
and   rs.data_cancellazione is null
and   r.ord_id=ord.ord_id

insert into siac_r_ordinativo_stato
(
	ord_id,
    ord_stato_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select ord.ord_id,
       stato.ord_stato_id,
       now(),
       'batch',
       stato.ente_proprietario_id
from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo, siac_v_bko_anno_bilancio anno,
     siac_d_ordinativo_stato stato
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   anno.bil_id=ord.bil_id
and   anno.anno_bilancio=2017
and   ord.ord_numero in (13940,13941,13942)
and   stato.ente_proprietario_id=2
and   stato.ord_stato_code='Q'

insert into siac_r_ordinativo_quietanza
(
  ord_id,
  ord_quietanza_data,
  ord_quietanza_numero,
  ord_quietanza_importo,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select ord.ord_id,
       now(),
       99,
       100,
       now(),
       'batch',
       ord.ente_proprietario_id
from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo, siac_v_bko_anno_bilancio anno
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   anno.bil_id=ord.bil_id
and   anno.anno_bilancio=2017
and   ord.ord_numero in (13940,13941,13942)

update siac_r_ordinativo_stato rs
set    validita_fine=null
from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo, siac_v_bko_anno_bilancio anno,
      siac_d_ordinativo_stato stato,siac_r_ordinativo_firma r
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   anno.bil_id=ord.bil_id
and   anno.anno_bilancio=2017
and   ord.ord_numero in (13940,13941,13942)
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   stato.ord_stato_code='T'
and   rs.data_cancellazione is null
and   r.ord_id=ord.ord_id


begin;
select *
from fnc_mif_flusso_elaborato_firme
( 2,
  2017,
  'REGP',
  'RICFIMIF',
  1540,
  'batch',
  now()::timestamp
);


select e.oil_ricevuta_errore_desc,
       oil.*
from siac_t_oil_ricevuta oil,siac_d_oil_ricevuta_errore e
where  oil.flusso_elab_mif_id=1540
and    e.oil_ricevuta_errore_id=oil.oil_ricevuta_errore_id

select mif.*
from mif_t_emfe_rr mif
where mif.flusso_elab_mif_id=1540;



update mif_t_emfe_rr mif
set   codice_funzione='I'
where mif.flusso_elab_mif_id=1540;

select *
from mif_t_flusso_elaborato mif
where mif.ente_proprietario_id=2
order by mif.flusso_elab_mif_id desc

select *
from mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=2
--529
-- 1540
select *
from mif_t_emfe_hrer mif
where mif.flusso_elab_mif_id=529;

select *
from mif_t_emfe_dr mif
where mif.flusso_elab_mif_id=529;

select *
from mif_t_emfe_rr mif
where mif.flusso_elab_mif_id=529;

rollback;
begin;
insert into mif_t_flusso_elaborato
(
  flusso_elab_mif_data,
  flusso_elab_mif_esito,
  flusso_elab_mif_esito_msg,
  flusso_elab_mif_file_nome,
  flusso_elab_mif_tipo_id,
  flusso_elab_mif_id_flusso_oil,
  flusso_elab_mif_num_ord_elab,
  flusso_elab_mif_num_subord_elab,
  validita_inizio,
  ente_proprietario_id,
  login_operazione,
  flusso_elab_mif_codice_flusso_oil,
  flusso_elab_mif_quiet_id
)
select
    flusso_elab_mif_data,
    'IN',
    'ELABORAZIONE IN CORSO',
    flusso_elab_mif_file_nome,
    flusso_elab_mif_tipo_id,
    flusso_elab_mif_id_flusso_oil,
    0,
    0,
    now(),
    ente_proprietario_id,
    login_operazione,
    flusso_elab_mif_codice_flusso_oil,
    flusso_elab_mif_quiet_id
from mif_t_flusso_elaborato mif
where mif.flusso_elab_mif_id=529

rollback;
begin;
insert into mif_t_emfe_hrer
(
  flusso_elab_mif_id,
  n_row,
  codice_flusso,
  tipo_record,
  data_ora_flusso,
  tipo_flusso,
  codice_abi_bt,
  codice_ente_bt,
  tipo_servizio,
  aid,
  num_ricevute,
  ente_proprietario_id
)
select
  1540,
  n_row,
  codice_flusso,
  tipo_record,
  data_ora_flusso,
  tipo_flusso,
  codice_abi_bt,
  codice_ente_bt,
  tipo_servizio,
  aid,
  num_ricevute,
  ente_proprietario_id
from mif_t_emfe_hrer mif
where mif.flusso_elab_mif_id=529;

begin;
insert into mif_t_emfe_rr
(
  flusso_elab_mif_id,
  n_row,
  codice_flusso,
  tipo_record,
  progressivo_ricevuta,
  id_tipo,
  data_messaggio,
  ora_messaggio,
  firma_nome,
  firma_data,
  firma_ora,
  esito_derivato,
  data_ora_creazione_ricevuta,
  qualificatore,
  codice_abi_bt,
  codice_ente,
  descrizione_ente,
  codice_ente_bt,
  data_ora_ricevuta,
  numero_documento,
  codice_funzione,
  numero_ordinativo,
  progressivo_ordinativo,
  data_ordinativo,
  esercizio,
  codice_esito,
  descrizione_esito,
  data_pagamento,
  importo_ordinativo,
  codice_pagamento,
  importo_ritenute,
  flag_copertura,
  valuta_beneficiario,
  valuta_ente,
  abi_beneficiario,
  cab_beneficiario,
  cc_beneficiario,
  coordinate_iban,
  carico_bollo,
  importo_bollo,
  carico_commisioni,
  importo_commissioni,
  carico_spese,
  importo_spese,
  num_assegno,
  data_emissione_assegno,
  data_estinzione_assegno,
  codice_versamento,
  numero_pratica,
  causale_pratica,
  num_proposta_reversale,
  nome_cognome,
  indirizzo,
  cap,
  localita,
  provincia,
  partita_iva,
  codice_fiscale,
  causale,
  num_pagamento_funzionario_delegato,
  progressivo_pagamento_funzionario_delegato,
  codice_ente_beneficiario,
  descrizione,
  ente_proprietario_id,
  cro
)
select

  1540,
  2,
  mif.codice_flusso,
  mif.tipo_record,
  mif.progressivo_ricevuta,
  mif.id_tipo,
  mif.data_messaggio,
  mif.ora_messaggio,
  mif.firma_nome,
  mif.firma_data,
  mif.firma_ora,
  mif.esito_derivato,
  mif.data_ora_creazione_ricevuta,
  mif.qualificatore,
  mif.codice_abi_bt,
  mif.codice_ente,
  mif.descrizione_ente,
  mif.codice_ente_bt,
  mif.data_ora_ricevuta,
  mif.numero_documento,
  mif.codice_funzione,
  ord.ord_numero::varchar,
  mif.progressivo_ordinativo,
  mif.data_ordinativo,
  mif.esercizio,
  mif.codice_esito,
  mif.descrizione_esito,
  mif.data_pagamento,
  mif.importo_ordinativo,
  mif.codice_pagamento,
  mif.importo_ritenute,
  mif.flag_copertura,
  mif.valuta_beneficiario,
  mif.valuta_ente,
  mif.abi_beneficiario,
  mif.cab_beneficiario,
  mif.cc_beneficiario,
  mif.coordinate_iban,
  mif.carico_bollo,
  mif.importo_bollo,
  mif.carico_commisioni,
  mif.importo_commissioni,
  mif.carico_spese,
  mif.importo_spese,
  mif.num_assegno,
  mif.data_emissione_assegno,
  mif.data_estinzione_assegno,
  mif.codice_versamento,
  mif.numero_pratica,
  mif.causale_pratica,
  mif.num_proposta_reversale,
  mif.nome_cognome,
  mif.indirizzo,
  mif.cap,
  mif.localita,
  mif.provincia,
  mif.partita_iva,
  mif.codice_fiscale,
  mif.causale,
  mif.num_pagamento_funzionario_delegato,
  mif.progressivo_pagamento_funzionario_delegato,
  mif.codice_ente_beneficiario,
  mif.descrizione,
  mif.ente_proprietario_id,
  mif.cro
from mif_t_emfe_rr mif, siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo,siac_v_bko_anno_bilancio anno
where mif.flusso_elab_mif_id=529
and   mif.id=18045
and   tipo.ente_proprietario_id=mif.ente_proprietario_id
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   ord.ord_numero in (13940,13941,13942)
and   anno.bil_id=ord.bil_id
and   anno.anno_bilancio=2017



select *
from mif_t_emfe_rr mif
where mif.flusso_elab_mif_id=1540;


