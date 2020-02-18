/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
select q.oil_qualificatore_code, q.oil_qualificatore_desc,
       e.oil_esito_derivato_code, e.oil_esito_derivato_desc,
       tipo.oil_ricevuta_tipo_code, tipo.oil_ricevuta_tipo_desc
from siac_d_oil_qualificatore q, siac_d_oil_ricevuta_tipo tipo, siac_d_oil_esito_derivato e
where q.ente_proprietario_id=2
and   q.login_operazione='admin-siope+'
and   e.oil_esito_derivato_id=q.oil_esito_derivato_id
and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id


select err.oil_ricevuta_errore_desc,
       err.oil_ricevuta_errore_code,
       tipo.oil_ricevuta_tipo_code,
       mif.tipo_documento,
       mif.tipo_movimento,
       mif.tipo_operazione,
       mif.data_creazione,
       mif.numero_documento,
       mif.numero_sospeso,
       mif.numero_bolletta_quietanza,
       mif.numero_bolletta_quietanza_storno,
       mif.importo,
       abs(mif.importo::numeric),
       mif.data_movimento,
       oil.oil_ord_numero,
       oil.oil_ord_importo,
       oil.oil_ord_importo_quiet,
       oil.oil_ord_importo_quiet_tot,
       oil.oil_ord_importo_storno,
       oil.oil_ricevuta_importo
from siac_t_oil_ricevuta oil, mif_t_giornalecassa mif,siac_d_oil_ricevuta_tipo tipo,
     siac_d_oil_ricevuta_errore err
where oil.ente_proprietario_id=2
and   oil.flusso_elab_mif_id=mif.flusso_elab_mif_id
and   oil.oil_progr_ricevuta_id=mif.mif_t_giornalecassa_id
and   err.oil_ricevuta_errore_id=oil.oil_ricevuta_errore_id
and   tipo.oil_ricevuta_tipo_id=oil.oil_ricevuta_tipo_id
order by oil.oil_ord_numero

-- 48 scarti per ordinativi gia quietanzati
select err.oil_ricevuta_errore_desc,
       mif.tipo_documento,
       mif.tipo_movimento,
       mif.tipo_operazione,
       mif.data_creazione,
       mif.numero_documento,
       mif.numero_sospeso,
       mif.numero_bolletta_quietanza,
       oil.oil_ord_numero,
       oil.oil_ord_importo,
       oil.oil_ord_importo_quiet,
       oil.oil_ord_importo_quiet_tot,
       rq.ord_quietanza_importo,
       stato.ord_stato_code
from siac_t_oil_ricevuta oil, mif_t_giornalecassa mif,
     siac_d_oil_ricevuta_errore err,
     siac_r_ordinativo_stato r, siac_d_ordinativo_stato stato,
     siac_r_ordinativo_quietanza rq
where oil.ente_proprietario_id=2
and   oil.flusso_elab_mif_id=mif.flusso_elab_mif_id
and   oil.oil_progr_ricevuta_id=mif.mif_t_giornalecassa_id
and   err.oil_ricevuta_errore_id=oil.oil_ricevuta_errore_id
and   r.ord_id=oil.oil_ord_id
and   stato.ord_stato_id=r.ord_stato_id
and   rq.ord_id=r.ord_id
and   r.data_cancellazione is null
and   r.validita_fine  is null
and   rq.data_cancellazione is null
and   rq.validita_fine  is null
order by oil.oil_ord_numero


select abs(-61591737.72::numeric)

select ord.ord_id,det.*
from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,siac_t_ordinativo_ts ts, siac_t_ordinativo_ts_det det
where tipo.ord_tipo_code='I'
and   tipo.ente_proprietario_id=2
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   ord.ord_numero::integer=11470
and   ts.ord_id=ord.ord_id
and   det.ord_ts_id=ts.ord_ts_id

104235357,88
104235357,88

select stato.ord_stato_code, r.*
from siac_r_ordinativo_stato r, siac_d_ordinativo_stato stato
where r.ord_id=30614
and   stato.ord_stato_id=r.ord_stato_id
order by r.validita_inizio, r.validita_fine

select *
from siac_r_ordinativo_firma r
where r.ord_id=30614

select *
from siac_r_ordinativo_storno r
where r.ord_id=30614

select *
from mif_t_flusso_elaborato mif
where mif.ente_proprietario_id=2
order by mif.flusso_elab_mif_id desc

select *
from mif_d_flusso_elaborato_tipo

-----------------------------------

select err.oil_ricevuta_errore_desc,
       err.oil_ricevuta_errore_code,
       tipo.oil_ricevuta_tipo_code,
       mif.tipo_movimento,
       mif.tipo_documento,
       mif.tipo_operazione,
       mif.numero_documento,
       mif.numero_bolletta_quietanza,
       mif.numero_bolletta_quietanza_storno,
       oil.oil_ord_numero,
       oil.oil_ord_importo,
       oil.oil_ricevuta_importo
from siac_t_oil_ricevuta oil, mif_t_giornalecassa mif,siac_d_oil_ricevuta_tipo tipo,
     siac_d_oil_ricevuta_errore err
where oil.ente_proprietario_id=2
and   oil.flusso_elab_mif_id=mif.flusso_elab_mif_id
and   oil.oil_progr_ricevuta_id=mif.mif_t_giornalecassa_id
and   err.oil_ricevuta_errore_id=oil.oil_ricevuta_errore_id
and   tipo.oil_ricevuta_tipo_id=oil.oil_ricevuta_tipo_id
--and   err.oil_ricevuta_errore_code='36'
and   err.oil_ricevuta_errore_code='27'
order by mif.tipo_movimento,oil.oil_ord_numero

select err.oil_ricevuta_errore_desc,
       mif.tipo_movimento,
       mif.tipo_documento,
       mif.tipo_operazione,
       mif.numero_documento,
       mif.numero_sospeso,
       mif.numero_bolletta_quietanza,
       oil.oil_ord_numero,
       oil.oil_ord_importo,
       oil.oil_ord_importo_quiet,
       oil.oil_ord_importo_quiet_tot,
       rq.ord_quietanza_importo,
       stato.ord_stato_code
from siac_t_oil_ricevuta oil, mif_t_giornalecassa mif,
     siac_d_oil_ricevuta_errore err,
     siac_r_ordinativo_stato r, siac_d_ordinativo_stato stato,
     siac_r_ordinativo_quietanza rq
where oil.ente_proprietario_id=2
and   oil.flusso_elab_mif_id=mif.flusso_elab_mif_id
and   oil.oil_progr_ricevuta_id=mif.mif_t_giornalecassa_id
and   err.oil_ricevuta_errore_id=oil.oil_ricevuta_errore_id
and   r.ord_id=oil.oil_ord_id
and   stato.ord_stato_id=r.ord_stato_id
and   rq.ord_id=r.ord_id
and   r.data_cancellazione is null
and   r.validita_fine  is null
and   rq.data_cancellazione is null
and   rq.validita_fine  is null
order by oil.oil_ord_numero

select oil.*,
       r.*
from siac_t_oil_ricevuta oil, siac_r_prov_cassa_oil_ricevuta r
where r.ente_proprietario_id=2
and   date_trunc('DAY',r.data_creazione)=date_trunc('DAY',now()::timestamp)
and   oil.oil_ricevuta_id=r.oil_ricevuta_id
-- 483

select oil.*,
       r.*
from siac_t_oil_ricevuta oil, siac_r_prov_cassa_oil_ricevuta r
where r.ente_proprietario_id=2
and   date_trunc('DAY',r.data_creazione)=date_trunc('DAY',now()::timestamp)
and   oil.oil_ricevuta_id=r.oil_ricevuta_id

select *
from mif_t_giornalecassa mif, siac_t_oil_ricevuta oil
where mif.tipo_documento like 'MANDATO%'
and   oil.flusso_elab_mif_id=mif.flusso_elab_mif_id
and   oil.oil_progr_ricevuta_id=mif.mif_t_giornalecassa_id
and   oil.oil_ricevuta_errore_id is null