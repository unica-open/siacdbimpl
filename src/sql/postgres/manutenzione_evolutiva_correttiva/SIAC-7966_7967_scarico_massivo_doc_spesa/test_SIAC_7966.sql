/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

select anno.anno_bilancio, ord.ord_numero
from siac_v_bko_anno_bilancio anno,
     siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo,
     siac_r_ordinativo_stato rs,siac_d_ordinativo_Stato stato
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   anno.bil_id=ord.bil_id
and   anno.anno_bilancio<=2019
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   stato.ord_stato_code!='A'
and   rs.data_cancellazione is null
and   rs.validita_fine is null

select anno.anno_bilancio, ord.ord_numero,ts.ord_ts_code::integer,
       stato_doc.doc_stato_code,tipo_doc.doc_tipo_code,
       doc.doc_anno, doc.doc_numero,sub.subdoc_numero
from siac_v_bko_anno_bilancio anno,
     siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo,
     siac_r_ordinativo_stato rs,siac_d_ordinativo_Stato stato,
     siac_t_ordinativo_ts ts,siac_r_subdoc_ordinativo_ts rsub,
     siac_t_subdoc sub,siac_t_doc doc,siac_d_doc_tipo tipo_doc,
     siac_r_doc_stato rs_doc,siac_d_doc_stato stato_doc
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   anno.bil_id=ord.bil_id
and   anno.anno_bilancio<=2019
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   stato.ord_stato_code!='A'
and   ts.ord_id=ord.ord_id
and   rsub.ord_ts_id=ts.ord_ts_id
and   sub.subdoc_id=rsub.subdoc_id
and   doc.doc_id=sub.doc_id
and   tipo_doc.doc_tipo_id=doc.doc_tipo_id
and   rs_doc.doc_id=doc.doc_id
and   stato_doc.doc_stato_id=rs_doc.doc_stato_id
and   stato_doc.doc_stato_code='EM'
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   rsub.data_cancellazione is null
and   rsub.validita_fine is null
and   rs_doc.data_cancellazione is null
and   rs_doc.validita_fine is null
and   ts.data_cancellazione is null
and   ts.validita_fine is null
order by 1,2,3
-- 153828
-- 40978  CMTO

select count(*)
from siac_dwh_documento_spesa d
where d.ente_proprietario_id=2
-- 252296
-- 57431 CMTO

-- select 252296-153828= 98468

-- select 57431-40978=16453 CMTO

/*bil_anno_ord VARCHAR(4),
anno_ord INTEGER,
num_ord NUMERIC,
num_subord

anno_doc INTEGER,
num_doc
num_subdoc
doc_id*/

select anno.anno_bilancio, ord.ord_numero,ts.ord_ts_code::integer,
       stato_doc.doc_stato_code,tipo_doc.doc_tipo_code,
       doc.doc_anno, doc.doc_numero,sub.subdoc_numero
from siac_v_bko_anno_bilancio anno,
     siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo,
     siac_r_ordinativo_stato rs,siac_d_ordinativo_Stato stato,
     siac_t_ordinativo_ts ts,siac_r_subdoc_ordinativo_ts rsub,
     siac_t_subdoc sub,siac_t_doc doc,siac_d_doc_tipo tipo_doc,
     siac_r_doc_stato rs_doc,siac_d_doc_stato stato_doc,
     siac_dwh_documento_spesa dw
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   anno.bil_id=ord.bil_id
and   anno.anno_bilancio<=2019
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   stato.ord_stato_code!='A'
and   ts.ord_id=ord.ord_id
and   rsub.ord_ts_id=ts.ord_ts_id
and   sub.subdoc_id=rsub.subdoc_id
and   doc.doc_id=sub.doc_id
and   tipo_doc.doc_tipo_id=doc.doc_tipo_id
and   rs_doc.doc_id=doc.doc_id
and   stato_doc.doc_stato_id=rs_doc.doc_stato_id
and   stato_doc.doc_stato_code='EM'
and   dw.doc_id=doc.doc_id
and   dw.num_subdoc=sub.subdoc_numero::integer
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   rsub.data_cancellazione is null
and   rsub.validita_fine is null
and   rs_doc.data_cancellazione is null
and   rs_doc.validita_fine is null
and   ts.data_cancellazione is null
and   ts.validita_fine is null
order by 1,2,3
-- 169898

-- select 169898-153828 =16070

--- OK
select anno.anno_bilancio, ord.ord_numero,ts.ord_ts_code::integer,
       stato_doc.doc_stato_code,tipo_doc.doc_tipo_code,
       doc.doc_anno, doc.doc_numero,sub.subdoc_numero
from siac_v_bko_anno_bilancio anno,
     siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo,
     siac_r_ordinativo_stato rs,siac_d_ordinativo_Stato stato,
     siac_t_ordinativo_ts ts,siac_r_subdoc_ordinativo_ts rsub,
     siac_t_subdoc sub,siac_t_doc doc,siac_d_doc_tipo tipo_doc,
     siac_r_doc_stato rs_doc,siac_d_doc_stato stato_doc--,
--     siac_dwh_documento_spesa dw
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   anno.bil_id=ord.bil_id
and   anno.anno_bilancio<=2018
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   stato.ord_stato_code!='A'
and   ts.ord_id=ord.ord_id
and   rsub.ord_ts_id=ts.ord_ts_id
and   sub.subdoc_id=rsub.subdoc_id
and   doc.doc_id=sub.doc_id
and   tipo_doc.doc_tipo_id=doc.doc_tipo_id
and   rs_doc.doc_id=doc.doc_id
and   stato_doc.doc_stato_id=rs_doc.doc_stato_id
and   stato_doc.doc_stato_code='EM'
and   not exists
(
select 1
from siac_t_subdoc sub1,siac_r_subdoc_ordinativo_ts rsub1,
     siac_t_ordinativo_ts ts1,siac_t_ordinativo ord1,siac_v_bko_anno_bilancio anno1
where sub1.doc_id=doc.doc_id
and   rsub1.subdoc_id=sub1.subdoc_id
and   ts1.ord_ts_id=rsub1.ord_ts_id
and   ord1.ord_id=ts1.ord_id
and   anno1.bil_id=ord1.bil_id
and   anno1.anno_bilancio>=2019
and   rsub1.data_cancellazione is null
and   rsub1.validita_fine is null
)
--and   dw.doc_id=doc.doc_id
--and   dw.num_subdoc=sub.subdoc_numero::integer
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   rsub.data_cancellazione is null
and   rsub.validita_fine is null
and   rs_doc.data_cancellazione is null
and   rs_doc.validita_fine is null
and   ts.data_cancellazione is null
and   ts.validita_fine is null
order by 1,2,3
-- 153760 2019
-- 105932 2018

-- OK
select anno.anno_bilancio, ord.ord_numero,ts.ord_ts_code::integer,
       stato_doc.doc_stato_code,tipo_doc.doc_tipo_code,
       doc.doc_anno, doc.doc_numero,
       doc.doc_id, sub.subdoc_numero, count(*)
from siac_v_bko_anno_bilancio anno,
     siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo,
     siac_r_ordinativo_stato rs,siac_d_ordinativo_Stato stato,
     siac_t_ordinativo_ts ts,siac_r_subdoc_ordinativo_ts rsub,
     siac_t_subdoc sub,siac_t_doc doc,siac_d_doc_tipo tipo_doc,
     siac_r_doc_stato rs_doc,siac_d_doc_stato stato_doc,
     siac_dwh_documento_spesa dw
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   anno.bil_id=ord.bil_id
and   anno.anno_bilancio<=2018
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   stato.ord_stato_code!='A'
and   ts.ord_id=ord.ord_id
and   rsub.ord_ts_id=ts.ord_ts_id
and   sub.subdoc_id=rsub.subdoc_id
and   doc.doc_id=sub.doc_id
and   tipo_doc.doc_tipo_id=doc.doc_tipo_id
and   rs_doc.doc_id=doc.doc_id
and   stato_doc.doc_stato_id=rs_doc.doc_stato_id
and   stato_doc.doc_stato_code='EM'
and   not exists
(
select 1
from siac_t_subdoc sub1,siac_r_subdoc_ordinativo_ts rsub1,
     siac_t_ordinativo_ts ts1,siac_t_ordinativo ord1,siac_v_bko_anno_bilancio anno1
where sub1.doc_id=doc.doc_id
and   rsub1.subdoc_id=sub1.subdoc_id
and   ts1.ord_ts_id=rsub1.ord_ts_id
and   ord1.ord_id=ts1.ord_id
and   anno1.bil_id=ord1.bil_id
and   anno1.anno_bilancio>=2019
and   rsub1.data_cancellazione is null
and   rsub1.validita_fine is null
)
and   dw.doc_id=doc.doc_id
and   dw.num_subdoc=sub.subdoc_numero::integer
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   rsub.data_cancellazione is null
and   rsub.validita_fine is null
and   rs_doc.data_cancellazione is null
and   rs_doc.validita_fine is null
and   ts.data_cancellazione is null
and   ts.validita_fine is null
group by anno.anno_bilancio, ord.ord_numero,ts.ord_ts_code::integer,
       stato_doc.doc_stato_code,tipo_doc.doc_tipo_code,
       doc.doc_anno, doc.doc_numero,
       doc.doc_id, sub.subdoc_numero
having count(*)>1

-- 91572  3

select *
from siac_dwh_documento_spesa dw
where dw.doc_id=91572
and   dw.num_subdoc=3

select count(*)
from siac_dwh_documento_spesa dw
-- 252296

select count(*)
from siac_dwh_documento_spesa_SIAC_7966
-- 252296

select count(*)
from siac_dwh_st_documento_spesa dw
-- 112622

-- select 252296-112622=139674

-- OK
create table siac_dwh_documento_spesa_bko_SIAC_7966
as select *
from siac_dwh_documento_spesa

select count(*)
from siac_dwh_documento_spesa_bko_SIAC_7966
-- 252296

-- OK
drop table siac_dwh_documento_spesa_SIAC_7966
create table siac_dwh_documento_spesa_SIAC_7966
as select * from siac_dwh_documento_spesa

drop table siac_dwh_st_documento_spesa
create table siac_dwh_st_documento_spesa as
select dw.*
from  siac_v_bko_anno_bilancio anno,
     siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo,
     siac_r_ordinativo_stato rs,siac_d_ordinativo_Stato stato,
     siac_t_ordinativo_ts ts,siac_r_subdoc_ordinativo_ts rsub,
     siac_t_subdoc sub,siac_t_doc doc,siac_d_doc_tipo tipo_doc,
     siac_r_doc_stato rs_doc,siac_d_doc_stato stato_doc,
     siac_dwh_documento_spesa_bko_SIAC_7966 dw
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   anno.bil_id=ord.bil_id
and   anno.anno_bilancio<=2018
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   stato.ord_stato_code!='A'
and   ts.ord_id=ord.ord_id
and   rsub.ord_ts_id=ts.ord_ts_id
and   sub.subdoc_id=rsub.subdoc_id
and   doc.doc_id=sub.doc_id
and   tipo_doc.doc_tipo_id=doc.doc_tipo_id
and   rs_doc.doc_id=doc.doc_id
and   stato_doc.doc_stato_id=rs_doc.doc_stato_id
and   stato_doc.doc_stato_code='EM'
and   not exists
(
select 1
from siac_t_subdoc sub1,siac_r_subdoc_ordinativo_ts rsub1,
     siac_t_ordinativo_ts ts1,siac_t_ordinativo ord1,siac_v_bko_anno_bilancio anno1
where sub1.doc_id=doc.doc_id
and   rsub1.subdoc_id=sub1.subdoc_id
and   ts1.ord_ts_id=rsub1.ord_ts_id
and   ord1.ord_id=ts1.ord_id
and   anno1.bil_id=ord1.bil_id
and   anno1.anno_bilancio>=2019
and   rsub1.data_cancellazione is null
and   rsub1.validita_fine is null
)
and   dw.doc_id=doc.doc_id
and   dw.num_subdoc=sub.subdoc_numero::integer
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   rsub.data_cancellazione is null
and   rsub.validita_fine is null
and   rs_doc.data_cancellazione is null
and   rs_doc.validita_fine is null
and   ts.data_cancellazione is null
and   ts.validita_fine is null

alter table siac_dwh_st_documento_spesa add data_storico TIMESTAMP WITHOUT TIME ZONE
update siac_dwh_st_documento_spesa set data_storico=now()

-- NO
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
--  and date_trunc('DAY',a.data_creazione)=date_trunc('DAY',now())
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  AND e.data_cancellazione IS NULL
  AND f.data_cancellazione IS NULL
  AND g.data_cancellazione IS NULL
  AND h.data_cancellazione IS NULL
),
doc_storico as
(
select anno.anno_bilancio, ord.ord_numero,ts.ord_ts_code::integer,
       stato_doc.doc_stato_code,tipo_doc.doc_tipo_code,
       doc.doc_anno, doc.doc_numero,
       doc.doc_id, sub.subdoc_numero,sub.subdoc_id
from siac_v_bko_anno_bilancio anno,
     siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo,
     siac_r_ordinativo_stato rs,siac_d_ordinativo_Stato stato,
     siac_t_ordinativo_ts ts,siac_r_subdoc_ordinativo_ts rsub,
     siac_t_subdoc sub,siac_t_doc doc,siac_d_doc_tipo tipo_doc,
     siac_r_doc_stato rs_doc,siac_d_doc_stato stato_doc
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   anno.bil_id=ord.bil_id
and   anno.anno_bilancio<=2020
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   stato.ord_stato_code!='A'
and   ts.ord_id=ord.ord_id
and   rsub.ord_ts_id=ts.ord_ts_id
and   sub.subdoc_id=rsub.subdoc_id
and   doc.doc_id=sub.doc_id
and   tipo_doc.doc_tipo_id=doc.doc_tipo_id
and   rs_doc.doc_id=doc.doc_id
and   stato_doc.doc_stato_id=rs_doc.doc_stato_id
and   stato_doc.doc_stato_code='EM'
and   not exists
(
select 1
from siac_t_subdoc sub1,siac_r_subdoc_ordinativo_ts rsub1,
     siac_t_ordinativo_ts ts1,siac_t_ordinativo ord1,siac_v_bko_anno_bilancio anno1
where sub1.doc_id=doc.doc_id
and   rsub1.subdoc_id=sub1.subdoc_id
and   ts1.ord_ts_id=rsub1.ord_ts_id
and   ord1.ord_id=ts1.ord_id
and   anno1.bil_id=ord1.bil_id
and   anno1.anno_bilancio>=2021
and   rsub1.data_cancellazione is null
and   rsub1.validita_fine is null
)
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   rsub.data_cancellazione is null
and   rsub.validita_fine is null
and   rs_doc.data_cancellazione is null
and   rs_doc.validita_fine is null
and   ts.data_cancellazione is null
and   ts.validita_fine is null
)
select doc_tot.doc_id,doc_tot.subdoc_id
from doc_totale doc_tot
where not exists
(
select 1
from doc_storico doc_st
where doc_st.doc_id=doc_tot.doc_id
and   doc_st.subdoc_id=doc_tot.subdoc_id
)
-- 27537

-- OK
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
--  and date_trunc('DAY',a.data_creazione)=date_trunc('DAY',now())
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
-- 116235

-- select 252296-116235=136061
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


begin;
delete from siac_dwh_documento_spesa
-- 252296
select
fnc_siac_dwh_documento_spesa
(
  2,
  now()::timestamp
)
--00:02:54; t
select count(*) from  siac_dwh_documento_spesa
select count(*) from  siac_dwh_st_documento_spesa
-- 112622


-- 20/01/2021 01:04:20
-- 140209