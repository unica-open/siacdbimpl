/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--- 16.05.2018 Sofia JIRA-siac-6137

select *
from siac_v_bko_ordinativo_op_valido op
where op.ente_proprietario_id=2
and   op.anno_bilancio=2018
and   op.ord_numero=8274



select op.ord_numero, op.ord_id,
       doc.doc_anno,
       doc.doc_numero,
       tipo.doc_tipo_code,
       sub.subdoc_numero,
       sub.subdoc_importo,
       sub.subdoc_importo_da_dedurre
from siac_v_bko_ordinativo_op_valido op,
     siac_r_subdoc_ordinativo_ts rsub, siac_t_ordinativo_ts ts,
     siac_t_subdoc sub,siac_t_doc doc, siac_d_doc_tipo tipo
where op.ente_proprietario_id=2
and   op.anno_bilancio=2018
and   op.ord_numero=8270
and   ts.ord_id=op.ord_id
and   sub.subdoc_id=rsub.subdoc_id
and   doc.doc_id=sub.doc_id
and   tipo.doc_tipo_id=doc.doc_tipo_id
and   rsub.ord_ts_id=ts.ord_ts_id
and   rsub.data_cancellazione  is null
and   rsub.validita_fine is null


select op.ord_numero, op.ord_id,
       doc.doc_anno,
       doc.doc_numero,
       tipo.doc_tipo_code,
       sub.subdoc_numero,
       sub.subdoc_importo,
       sub.subdoc_importo_da_dedurre,
       r.doc_id_a,
       r.doc_importo_da_dedurre
from siac_v_bko_ordinativo_op_valido op,
     siac_r_subdoc_ordinativo_ts rsub, siac_t_ordinativo_ts ts,
     siac_t_subdoc sub,siac_t_doc doc, siac_d_doc_tipo tipo,
     siac_r_doc r
where op.ente_proprietario_id=2
and   op.anno_bilancio=2018
and   op.ord_numero=8270
and   ts.ord_id=op.ord_id
and   sub.subdoc_id=rsub.subdoc_id
and   doc.doc_id=sub.doc_id
and   tipo.doc_tipo_id=doc.doc_tipo_id
and   rsub.ord_ts_id=ts.ord_ts_id
and   r.doc_id_da=doc.doc_id
and   rsub.data_cancellazione  is null
and   rsub.validita_fine is null
and   r.data_cancellazione  is null
and   r.validita_fine is null

-- ord_id=84231

select * from
fnc_mif_ordinativo_documenti_splus
(84235,-- ordinativoId integer,
 30,--													           numeroDocumenti integer,
 'FPR|FAT,NCD',   --                                                            tipiDocumento   varchar,
 'ANALOGICO|9999999999999999',--                                                               docAnalogico    varchar,
 'dataScadenzaDopoSospensione',--                                                              attrCodeDataScad varchar,
 'Spesa - MissioniProgrammi|N',--                                                              titoloCap        varchar,
 '99',--                                                              codicePccUfficio varchar,
 2,--                                                   	           enteProprietarioId integer,
 now()::timestamp,--                                                              dataElaborazione timestamp,
 now()::timestamp --                                                             dataFineVal timestamp
 )


 select doc.doc_anno annoDoc, doc.doc_numero numeroDoc, tipo.doc_tipo_code tipoDoc,
        'P'::varchar tipoColl,doc.doc_id docPrincId,
        null annoDocNcd, null numeroDocNcd, null tipoDocNcd,
        lpad(extract('day' from doc.doc_data_emissione)::varchar,2,'0')||'/'||
        lpad(extract('month' from doc.doc_data_emissione)::varchar,2,'0')||'/'||
        extract('year' from doc.doc_data_emissione) dataDoc,
        sog.codice_fiscale codfiscDoc, sog.partita_iva partivaDoc,
        doc.doc_id docId,
        doc.pccuff_id pccuffId,
        subdoc.subdoc_data_scadenza datascadDoc,
        doc.siope_documento_tipo_id siopeDocTipoId,
        doc.doc_sdi_lotto_siope  siopeSdiLotto,
        doc.siope_documento_tipo_analogico_id siopeDocAnTipoId,
        sum(subdoc.subdoc_importo) importoDoc,
        coalesce(sum(subdoc.subdoc_splitreverse_importo),0) importoSplitDoc,
        null importoDaDedurre,
        null importoNcd,
        null numeroNcd,
        null totaleImportoNcd,
        null importoRipartNcd
  from siac_t_doc doc, siac_t_subdoc subdoc, siac_r_subdoc_ordinativo_ts subdocTs,
       siac_t_ordinativo_ts ordts, siac_d_doc_tipo tipo,
       siac_r_doc_sog rsog, siac_t_soggetto sog
--  where ordts.ord_id=82944
--  where ordts.ord_id=83437
--  where ordts.ord_id=83430
  where ordts.ord_id=84231
  and   subdocts.ord_ts_id=ordts.ord_ts_id
  and   subdoc.subdoc_id=subdocts.subdoc_id
  and   doc.doc_id=subdoc.doc_id
  and   tipo.doc_tipo_id=doc.doc_tipo_id
  and   fnc_mif_isDocumentoCommerciale_splus(doc.doc_id,'FPR','FAT','NCD')=true
  and   tipo.doc_tipo_code!='ALG'
  and   rsog.doc_id=doc.doc_id
  and   sog.soggetto_id=rsog.soggetto_id
  and   ordts.data_cancellazione is null and ordts.validita_fine is null
  and   subdocts.data_cancellazione is null AND subdocts.validita_fine is null
  and   subdoc.data_cancellazione is null and subdoc.validita_fine is null
  and   doc.data_cancellazione is null and doc.validita_fine is null
  and   tipo.data_cancellazione is null
  and   rsog.data_cancellazione is null and rsog.validita_fine is null
  and   sog.data_cancellazione is null
  and   date_trunc('day',now()::timestamp)>=date_trunc('day',tipo.validita_inizio)
  and   date_trunc('day',now()::timestamp)<=date_trunc('day',coalesce(tipo.validita_fine,now()::timestamp))
  group by doc.doc_anno , doc.doc_numero , tipo.doc_tipo_code,
           lpad(extract('day' from doc.doc_data_emissione)::varchar,2,'0')||'/'||
           lpad(extract('month' from doc.doc_data_emissione)::varchar,2,'0')||'/'||
           extract('year' from doc.doc_data_emissione),
           sog.codice_fiscale, sog.partita_iva, doc.doc_id,doc.pccuff_id,subdoc.subdoc_data_scadenza,
           doc.siope_documento_tipo_id, doc.doc_sdi_lotto_siope,doc.siope_documento_tipo_analogico_id
  union
  (
   with
   docS as
   (
    select  doc.doc_anno annoDoc, doc.doc_numero numeroDoc, tipo.doc_tipo_code tipoDoc,
           'S'::varchar tipoColl,doc.doc_id docPrincId,
           docNcd.doc_anno annoDocNcd, docNcd.doc_numero numeroDocNcd, tipoNcd.doc_tipo_code tipoDocNcd,
           lpad(extract('day' from docNcd.doc_data_emissione)::varchar,2,'0')||'/'||
           lpad(extract('month' from docNcd.doc_data_emissione)::varchar,2,'0')||'/'||
           extract('year' from docNcd.doc_data_emissione) dataDoc,
           sog.codice_fiscale codfiscDoc, sog.partita_iva partivaDoc,
           docNcd.doc_id docId,
           docNcd.pccuff_id pccuffId,
           docNcd.doc_data_emissione datascadDoc,
           docNcd.siope_documento_tipo_id siopeDocTipoId,
           docNcd.doc_sdi_lotto_siope  siopeSdiLotto,
           docNcd.siope_documento_tipo_analogico_id siopeDocAnTipoId,
           sum(subdoc.subdoc_importo) importoDoc,
           0 importoSplitDoc,
           sum(subdoc.subdoc_importo_da_dedurre) importoDaDedurre,
           sum(rdoc.doc_importo_da_dedurre) importoNcd
    from siac_t_doc doc, siac_t_subdoc subdoc, siac_r_subdoc_ordinativo_ts subdocTs,
         siac_t_ordinativo_ts ordts, siac_d_doc_tipo tipo,
         siac_r_doc rdoc, siac_d_relaz_tipo tipoRel,
         siac_t_doc docNcd,  siac_d_doc_tipo tipoNcd,
         siac_r_doc_sog rsog, siac_t_soggetto sog
--    where ordts.ord_id=82944
--    where ordts.ord_id=83437
--    where ordts.ord_id=83430
  where ordts.ord_id=84231
    and   subdocts.ord_ts_id=ordts.ord_ts_id
    and   subdoc.subdoc_id=subdocts.subdoc_id
    and   doc.doc_id=subdoc.doc_id
    and   tipo.doc_tipo_id=doc.doc_tipo_id
    and   fnc_mif_isDocumentoCommerciale_splus(doc.doc_id,'FPR','FAT','NCD')=true
    and   tipo.doc_tipo_code!='ALG'
    and   rdoc.doc_id_da=doc.doc_id
    and   docncd.doc_id=rdoc.doc_id_a
    and   tipoRel.relaz_tipo_id=rdoc.relaz_tipo_id
    and   tipoRel.relaz_tipo_code='NCD'
    and   fnc_mif_isDocumentoCommerciale_splus(docNcd.doc_id,'FPR','FAT','NCD')=true
    and   tipoNcd.doc_tipo_id=docNcd.doc_tipo_id
    and   rsog.doc_id=docNcd.doc_id
    and   sog.soggetto_id=rsog.soggetto_id
    and   ordts.data_cancellazione is null and ordts.validita_fine is null
    and   subdocts.data_cancellazione is null AND subdocts.validita_fine is null
    and   subdoc.data_cancellazione is null and subdoc.validita_fine is null
    and   doc.data_cancellazione is null and doc.validita_fine is null
    and   docNcd.data_cancellazione is null and docNcd.validita_fine is null
    and   rsog.data_cancellazione is null and rsog.validita_fine is null
    and   rdoc.data_cancellazione is null and rdoc.validita_fine is null
    and   sog.data_cancellazione is null
    group by  doc.doc_anno , doc.doc_numero , tipo.doc_tipo_code,doc.doc_id,
              docNcd.doc_anno , docNcd.doc_numero , tipoNcd.doc_tipo_code,
              lpad(extract('day' from docNcd.doc_data_emissione)::varchar,2,'0')||'/'||
              lpad(extract('month' from docNcd.doc_data_emissione)::varchar,2,'0')||'/'||
              extract('year' from docNcd.doc_data_emissione),
              sog.codice_fiscale, sog.partita_iva, docNcd.doc_id,docNcd.pccuff_id,docNcd.doc_data_emissione,
              docNcd.siope_documento_tipo_id, docNcd.doc_sdi_lotto_siope,docNcd.siope_documento_tipo_analogico_id
   ),
   docCountNcd as
   (
    select doc.doc_anno annoDoc, doc.doc_numero numeroDoc, tipo.doc_tipo_code tipoDoc,
           'S'::varchar tipoColl,doc.doc_id docPrincId,
           sum(rdoc.doc_importo_da_dedurre) totaleImportoNcd,
           count(*) numeroNcd
    from siac_t_doc doc, siac_t_subdoc subdoc, siac_r_subdoc_ordinativo_ts subdocTs,
         siac_t_ordinativo_ts ordts, siac_d_doc_tipo tipo,
         siac_r_doc rdoc, siac_d_relaz_tipo tipoRel,
         siac_t_doc docNcd, siac_d_doc_tipo tipoNcd
--    where ordts.ord_id=82944
--    where ordts.ord_id=83437
--  where ordts.ord_id=83430
  where ordts.ord_id=84231
    and   subdocts.ord_ts_id=ordts.ord_ts_id
    and   subdoc.subdoc_id=subdocts.subdoc_id
    and   doc.doc_id=subdoc.doc_id
    and   tipo.doc_tipo_id=doc.doc_tipo_id
    and   fnc_mif_isDocumentoCommerciale_splus(doc.doc_id,'FPR','FAT','NCD')=true
    and   tipo.doc_tipo_code!='ALG'
    and   rdoc.doc_id_da=doc.doc_id
    and   docncd.doc_id=rdoc.doc_id_a
    and   tipoRel.relaz_tipo_id=rdoc.relaz_tipo_id
    and   tipoRel.relaz_tipo_code='NCD'
    and   fnc_mif_isDocumentoCommerciale_splus(docNcd.doc_id,'FPR','FAT','NCD')=true
    and   tipoNcd.doc_tipo_id=docNcd.doc_tipo_id
    and   ordts.data_cancellazione is null and ordts.validita_fine is null
    and   subdocts.data_cancellazione is null AND subdocts.validita_fine is null
    and   subdoc.data_cancellazione is null and subdoc.validita_fine is null
    and   doc.data_cancellazione is null and doc.validita_fine is null
    and   docNcd.data_cancellazione is null and docNcd.validita_fine is null
    and   rdoc.data_cancellazione is null and rdoc.validita_fine is null
    group by doc.doc_anno , doc.doc_numero, tipo.doc_tipo_code ,doc.doc_id
   )
   select docS.*,
          docCountNcd.numeroNcd,
          docCountNcd.totaleImportoNcd,
          round((docs.importoDaDedurre*docS.importoNcd)/docCountNcd.totaleImportoNcd,2) importoRipartNcd
   from docS, docCountNcd
   where docS.docPrincId=docCountNcd.docPrincId
   --and   'S'='N'
  )
  order by 1,2,3,4,6,7,8