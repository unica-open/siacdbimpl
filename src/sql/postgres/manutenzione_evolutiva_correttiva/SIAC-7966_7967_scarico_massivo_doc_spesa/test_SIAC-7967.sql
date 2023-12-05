/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
select count(*)
from siac_dwh_documento_spesa_SIAC_7966
-- 252296

select  count(*)
from siac_dwh_st_documento_spesa
-- 112622

rollback;
begin;
delete from siac_dwh_documento_spesa_SIAC_7966
select
fnc_siac_dwh_documento_spesa_siac_SIAC_7966
(
  2,
  now()::timestamp
)
-- 00:03:40 no modifica
-- 02:44; no modifica 563
-- 00:03:58 si modifica 561
-- 00:03:07
-- 02:49;

select count(*)
from siac_dwh_documento_spesa_SIAC_7966


select *
from siac_dwh_log_elaborazioni a
where
a.ente_proprietario_id=2
and a.fnc_name='fnc_siac_dwh_documento_spesa'
order by a.log_id desc
--2 - 2021-01-20 17:05:26.766993 -   Fine eliminazione dati pregressi - 2021-01-20 17:05:42.807413+01 - Fine funzione carico documenti spesa - variabili (FNC_SIAC_DWH_DOCUMENTO_SPESA) - 2021-01-20 17:09:48.52218+01 - Fine funzione carico documenti spesa - storici (FNC_SIAC_DWH_DOCUMENTO_SPESA) - 2021-01-20 17:09:48.686282+01

--2 - 2021-01-20 17:13:51.345855 -   Fine eliminazione dati pregressi - 2021-01-20 17:14:08.075417+01 - Fine funzione carico documenti spesa - variabili (FNC_SIAC_DWH_DOCUMENTO_SPESA) - 2021-01-20 17:17:24.943957+01 - Fine funzione carico documenti spesa - storici (FNC_SIAC_DWH_DOCUMENTO_SPESA) - 2021-01-20 17:17:33.276599+01

with
doc_totale as
(
select distinct
  --h.subdoc_id,a.doc_id,b.doc_tipo_id,c.doc_fam_tipo_id,d.doc_gruppo_tipo_id,e.doc_stato_r_id,f.doc_stato_id,
  b.doc_gruppo_tipo_id,
  g.ente_proprietario_id, g.ente_denominazione,
  a.doc_anno, a.doc_numero, a.doc_desc, a.doc_importo,
  case when a.doc_beneficiariomult= false then 'F' else 'T' end doc_beneficiariomult,
  a.doc_data_emissione, a.doc_data_scadenza,
  case when a.doc_collegato_cec = false then 'F' else 'T' end doc_collegato_cec,
  f.doc_stato_code, f.doc_stato_desc,
  c.doc_fam_tipo_code, c.doc_fam_tipo_desc, b.doc_tipo_code, b.doc_tipo_desc,
  a.doc_id, a.pcccod_id, a.pccuff_id,
  case when a.doc_contabilizza_genpcc= false then 'F' else 'T' end doc_contabilizza_genpcc,
  h.subdoc_numero, h.subdoc_desc, h.subdoc_importo, h.subdoc_nreg_iva, h.subdoc_data_scadenza,
  h.subdoc_convalida_manuale, h.subdoc_importo_da_dedurre, h.subdoc_splitreverse_importo,
  case when h.subdoc_pagato_cec = false then 'F' else 'T' end subdoc_pagato_cec,
  h.subdoc_data_pagamento_cec,
  a.codbollo_id, h.subdoc_id,h.comm_tipo_id,
  h.notetes_id,h.dist_id,h.contotes_id,
  a.doc_sdi_lotto_siope,
  n.siope_documento_tipo_code, n.siope_documento_tipo_desc, n.siope_documento_tipo_desc_bnkit,
  o.siope_documento_tipo_analogico_code, o.siope_documento_tipo_analogico_desc, o.siope_documento_tipo_analogico_desc_bnkit,
  i.siope_tipo_debito_code, i.siope_tipo_debito_desc, i.siope_tipo_debito_desc_bnkit,
  l.siope_assenza_motivazione_code, l.siope_assenza_motivazione_desc, l.siope_assenza_motivazione_desc_bnkit,
  m.siope_scadenza_motivo_code, m.siope_scadenza_motivo_desc, m.siope_scadenza_motivo_desc_bnkit
  from siac_t_doc a
  left join siac_d_siope_documento_tipo n on n.siope_documento_tipo_id = a.siope_documento_tipo_id
                                     and n.data_cancellazione is null
                                     and n.validita_fine is null
  left join siac_d_siope_documento_tipo_analogico o on o.siope_documento_tipo_analogico_id = a.siope_documento_tipo_analogico_id
                                             and o.data_cancellazione is null
                                             and o.validita_fine is null
  ,siac_d_doc_tipo b,siac_d_doc_fam_tipo c,
  --siac_d_doc_gruppo d,
  siac_r_doc_stato e,
  siac_d_doc_stato f,
  siac_t_ente_proprietario g,
  siac_t_subdoc h
  left join siac_d_siope_tipo_debito i on i.siope_tipo_debito_id = h.siope_tipo_debito_id
                                     and i.data_cancellazione is null
                                     and i.validita_fine is null
  left join siac_d_siope_assenza_motivazione l on l.siope_assenza_motivazione_id = h.siope_assenza_motivazione_id
                                             and l.data_cancellazione is null
                                             and l.validita_fine is null
  left join siac_d_siope_scadenza_motivo m on m.siope_scadenza_motivo_id = h.siope_scadenza_motivo_id
                                             and m.data_cancellazione is null
                                             and m.validita_fine is null
  where b.doc_tipo_id=a.doc_tipo_id
  and c.doc_fam_tipo_id=b.doc_fam_tipo_id
  --and b.doc_gruppo_tipo_id=d.doc_gruppo_tipo_id
  and e.doc_id=a.doc_id
  and now() BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, now())
  and f.doc_stato_id=e.doc_stato_id
  and g.ente_proprietario_id=a.ente_proprietario_id
  and g.ente_proprietario_id=2--p_ente_proprietario_id
  AND c.doc_fam_tipo_code in ('S','IS')
  and h.doc_id=a.doc_id
  and date_trunc('DAY',a.data_creazione)=date_trunc('DAY',now())
  and  not exists
  (
   select 1
   from  siac_t_bil anno,siac_t_periodo per,
         siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo,
         siac_r_ordinativo_stato rs,siac_d_ordinativo_Stato stato,
         siac_t_ordinativo_ts ts,siac_r_subdoc_ordinativo_ts rsub
   where f.doc_stato_code='EM'
   and   rsub.subdoc_id=h.subdoc_id
   and   ts.ord_ts_id=rsub.ord_ts_id
   and   ord.ord_id=ts.ord_id
   and   tipo.ord_tipo_id=ord.ord_tipo_id
   and   tipo.ord_tipo_code='P'
   and   anno.bil_id=ord.bil_id
   and   per.periodo_id=anno.periodo_id
   and   per.anno::integer<=2018
   and   rs.ord_id=ord.ord_id
   and   stato.ord_stato_id=rs.ord_stato_id
   and   stato.ord_stato_code!='A'
   and   not exists
   (
    select 1
    from siac_t_subdoc sub1,siac_r_subdoc_ordinativo_ts rsub1,
         siac_t_ordinativo_ts ts1,siac_t_ordinativo ord1,
         siac_t_bil anno1,siac_t_periodo per1
    where sub1.doc_id=a.doc_id
    and   rsub1.subdoc_id=sub1.subdoc_id
    and   ts1.ord_ts_id=rsub1.ord_ts_id
    and   ord1.ord_id=ts1.ord_id
    and   anno1.bil_id=ord1.bil_id
    and   per1.periodo_id=anno1.bil_id
    and   per1.anno::integer>=2019
    and   rsub1.data_cancellazione is null
    and   rsub1.validita_fine is null
   )
   and   rsub.data_cancellazione is null
   and   rsub.validita_fine is null
   and   ts.data_cancellazione is null
   and   ts.validita_fine is null
   and   rs.data_cancellazione is null
   and   rs.validita_fine is null
  )
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  AND e.data_cancellazione IS NULL
  AND f.data_cancellazione IS NULL
  AND g.data_cancellazione IS NULL
  AND h.data_cancellazione IS NULL
)
select doc_tot.doc_id,doc_tot.subdoc_id,doc_tot.doc_stato_code
from doc_totale doc_tot
-- 369

rollback;
begin;
--delete from siac_dwh_documento_spesa_SIAC_7966
select
fnc_siac_dwh_documento_spesa
(
  2,
  now()::timestamp
)
-- 00:03:40 no modifica
-- 02:44; no modifica 563
-- 00:03:58 si modifica 561
-- 00:03:07
-- 02:49;

select count(*)
from siac_dwh_documento_spesa


select *
from siac_dwh_log_elaborazioni a
where
a.ente_proprietario_id=2
and a.fnc_name='fnc_siac_dwh_documento_spesa'
order by a.log_id desc
-- 2 - 2021-01-20 17:26:39.198366 -   Fine eliminazione dati pregressi - 2021-01-20 17:27:13.036684+01 - Fine funzione carico documenti spesa (FNC_SIAC_DWH_DOCUMENTO_SPESA) - 2021-01-20 17:30:55.550112+01 - Fine funzione carico documenti spesa - storici (FNC_SIAC_DWH_DOCUMENTO_SPESA) - 2021-01-20 17:31:03.013713+01
-- 2 - 2021-01-20 17:41:15.752111 -   Fine eliminazione dati pregressi - 2021-01-20 17:41:22.827833+01 - Fine funzione carico documenti spesa - variabili (FNC_SIAC_DWH_DOCUMENTO_SPESA) - 2021-01-20 17:44:33.310778+01 - Fine funzione carico documenti spesa - storici (FNC_SIAC_DWH_DOCUMENTO_SPESA) - 2021-01-20 17:44:39.167488+01