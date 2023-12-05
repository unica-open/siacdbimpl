/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- 08.05.2018 Sofia siac-6137
-- Gestione importo note di  credito

/*16/04/2018
Gestione Ordinativi: Calcolo corretto importo nota di credito in presenza di più quote e note.
Si allega documento e Excel con formula ed esempi.
Si precisa che ad oggi la valorizzazione del tag "importo_siope" nella struttura Fattura_Siope per le note di credito funziona nei seguenti casi:
 - fattura con più quote ma unica nota di credito;
 - fattura con unica quota, ma più note di credito;
 - fattura con più quote e più note di credito ma pagate con unico mandato.
 In questi casi, l'importo della nota di credito è esatto perchè è quello collegato alla fattura/quota.

 Mentre, è da correggere il caso in cui mi trovo ad avere una fattura con più quote (tutte con un parte di quota stornata),
 stornata da più note di credito che finiscono su mandati diversi (caso CMTO, mi pare se ne sai verificato uno).

Il tutto nasce dal fatto che su Contabilia sappiamo quanto di ciascuna nota è collegato alla fattura intera mentre a livello
di quota sappiamo qual'è l'importo da stornare nella singola quota ma non come questo sia spalmato sulle quote.
Si è cercato di trovare una formula che sia la stessa per tutti i casi:
La formula è la seguente:
ImportoNotaMif = (IMPQM * IMPN)/TOTN
Dove:
ImportoNotaMif = importo della quota di nota che deve andare sul tag importo_siope per nota di credito
IMPQM = somma degli importi 'lordi' di tutte le quote che sono pagate nello stesso mandato.
Ossia è l'importo della fattura impostato nel tag importo_siope
IMPN = importo della singola nota che si storna sulla fattura
TOTN = importo totale di tutti gli importi delle note che si stornano nella fattura. Importo totale stornato nella fattura.
Arrotondiamo il calcolo alla 2 cifra di decimali.
*/

/*
ImportoNotaMif = (IMPQM * IMPN)/TOTN

IMPQM=sum(sub.subdoc_importo) delle quote del documento FAT collegate all'ordinativo
IMPN=sum(siac_r_doc.doc_importo_da_dedurre) per la singola NDC collegata al documento FAT collegato all'ordinativo
TOTN=sum(siac_r_doc.doc_importo_da_dedurre) di tutte le NDC collegate al documento FAT collegato all'ordinativo

nel caso in cui ci sia una sola NCD collegata al documento
ImportoNotaMif=IMPN, altrimenti risulterebbe ImportoNotaMif=IMPQM
*/

-- compilare
-- fnc_mif_ordinativo_documenti_splus
-- fnc_mif_ordinativo_spesa_splus


with
documenti as
(
select op.ord_id,
       op.ord_numero,
       doc.doc_id,
       tipo.doc_tipo_code,
       sum(sub.subdoc_importo) importo_documento
from siac_v_bko_ordinativo_op_valido op,siac_t_ordinativo_ts ts,
     siac_r_subdoc_ordinativo_ts rsub, siac_t_subdoc sub, siac_t_doc doc  ,siac_d_doc_tipo tipo
where op.ente_proprietario_id=2
and   op.anno_bilancio=2018
and   ts.ord_id=op.ord_id
and   rsub.ord_ts_id=ts.ord_ts_id
and   sub.subdoc_id=rsub.subdoc_id
and   doc.doc_id=sub.doc_id
and   tipo.doc_tipo_id=doc.doc_tipo_id
and   tipo.doc_tipo_code='FAT'
and   exists
(
select 1
from siac_r_doc rdoc,siac_d_relaz_tipo rel
where rdoc.doc_id_da=doc.doc_id
and   rel.relaz_tipo_id=rdoc.relaz_tipo_id
and   rel.relaz_tipo_code='NCD'
and   rdoc.data_cancellazione is null
and   rdoc.validita_fine is null
)
and   rsub.data_cancellazione is null
and   rsub.validita_fine is null
group by op.ord_id,op.ord_numero,
         doc.doc_id,
         tipo.doc_tipo_code
order by 1,2
),
documentiNoteTotale as
(
select doc.doc_id,
       tipo.doc_tipo_code,
       sum(rdoc.doc_importo_da_dedurre) totale_note_credito
from siac_t_subdoc sub, siac_t_doc doc  ,siac_d_doc_tipo tipo,
     siac_r_doc rdoc,siac_d_relaz_tipo rel,
     siac_t_doc ncd--,siac_t_subdoc subncd
where  tipo.ente_proprietario_id=2
and    tipo.doc_tipo_code='FAT'
and    tipo.doc_tipo_id=doc.doc_tipo_id
and    doc.doc_id=sub.doc_id
and   rdoc.doc_id_da=doc.doc_id
and   ncd.doc_id=rdoc.doc_id_a
--and   subncd.doc_id=ncd.doc_id
and   rel.relaz_tipo_id=rdoc.relaz_tipo_id
and   rel.relaz_tipo_code='NCD'
and   exists
(
select 1
from siac_v_bko_ordinativo_op_valido op,siac_t_ordinativo_ts ts,
     siac_r_subdoc_ordinativo_ts rsub
where sub.subdoc_id=rsub.subdoc_id
and   rsub.ord_ts_id=ts.ord_ts_id
and   op.anno_bilancio=2018
and   ts.ord_id=op.ord_id
and   rsub.data_cancellazione is null
and   rsub.validita_fine is null
)
and   rdoc.data_cancellazione is null
and   rdoc.validita_fine is null
group by doc.doc_id,
       tipo.doc_tipo_code
order by 1,2
),
notecredito as
(
select doc.doc_id,
       tipo.doc_tipo_code,
       ncd.doc_id doc_id_nota_credito,
       sum(rdoc.doc_importo_da_dedurre) importo_nota_credito
from siac_t_subdoc sub, siac_t_doc doc  ,siac_d_doc_tipo tipo,
     siac_r_doc rdoc,siac_d_relaz_tipo rel,
     siac_t_doc ncd--,siac_t_subdoc subncd
where  tipo.ente_proprietario_id=2
and    tipo.doc_tipo_code='FAT'
and    tipo.doc_tipo_id=doc.doc_tipo_id
and    doc.doc_id=sub.doc_id
and   rdoc.doc_id_da=doc.doc_id
and   ncd.doc_id=rdoc.doc_id_a
--and   subncd.doc_id=ncd.doc_id
and   rel.relaz_tipo_id=rdoc.relaz_tipo_id
and   rel.relaz_tipo_code='NCD'
and   exists
(
select 1
from siac_v_bko_ordinativo_op_valido op,siac_t_ordinativo_ts ts,
     siac_r_subdoc_ordinativo_ts rsub
where sub.subdoc_id=rsub.subdoc_id
and   rsub.ord_ts_id=ts.ord_ts_id
and   op.anno_bilancio=2018
and   ts.ord_id=op.ord_id
and   rsub.data_cancellazione is null
and   rsub.validita_fine is null
)
and   rdoc.data_cancellazione is null
and   rdoc.validita_fine is null
group by doc.doc_id,
       tipo.doc_tipo_code,
       ncd.doc_id
order by 1,2
)
select documenti.*,
       documentiNoteTotale.totale_note_credito,
       notecredito.doc_id_nota_credito,
       notecredito.importo_nota_credito,
       round((documenti.importo_documento* notecredito.importo_nota_credito) /  documentiNoteTotale.totale_note_credito,2) --(IMPQM * IMPN)/TOTN
from documenti, documentiNoteTotale, notecredito
where documenti.doc_id=documentiNoteTotale.doc_id
and  documenti.doc_id=notecredito.doc_id


-- 7802 , 7804

select op.*
from siac_v_bko_ordinativo_op_stati op
where op.ente_proprietario_id=2
and   op.anno_bilancio=2018
and   op.ord_numero in (7802 , 7804)
order by op.ord_numero, op.statoord_validita_inizio, op.statoord_validita_fine
/*doc_id=72993
ord_numero=7800
ord_id=83437*/

select *
from siac_t_ordinativo ord
where ord.ord_id in
(83440,83443)


-- 27/03/2018 16:38:58

SELECT mif.*
from mif_d_flusso_elaborato mif,mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
order by mif.flusso_elab_mif_ordine

select * from
fnc_mif_ordinativo_documenti_splus
(83443,-- ordinativoId integer,
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
        null importoNcd,
        null importoNcdNew,
        null numeroNcd,
        null importoRipartNcd,
        null importoRipartNcdNew
  from siac_t_doc doc, siac_t_subdoc subdoc, siac_r_subdoc_ordinativo_ts subdocTs,
       siac_t_ordinativo_ts ordts, siac_d_doc_tipo tipo,
       siac_r_doc_sog rsog, siac_t_soggetto sog
--  where ordts.ord_id=82944
--  where ordts.ord_id=83437
--  where ordts.ord_id=83430
  where ordts.ord_id=83440
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
           sum(subdoc.subdoc_importo_da_dedurre) importoNcd,
           sum(rdoc.doc_importo_da_dedurre) importoNcdNew
    from siac_t_doc doc, siac_t_subdoc subdoc, siac_r_subdoc_ordinativo_ts subdocTs,
         siac_t_ordinativo_ts ordts, siac_d_doc_tipo tipo,
         siac_r_doc rdoc, siac_d_relaz_tipo tipoRel,
         siac_t_doc docNcd,  siac_d_doc_tipo tipoNcd,
         siac_r_doc_sog rsog, siac_t_soggetto sog
--    where ordts.ord_id=82944
--    where ordts.ord_id=83437
--    where ordts.ord_id=83430
  where ordts.ord_id=83440
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
  where ordts.ord_id=83440
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
          round(docS.importoNcd/docCountNcd.numeroNcd,2) importoRipartNcd,
          round((docs.importoDoc*docS.importoNcdNew)/docCountNcd.totaleImportoNcd,2) importoRipartNcdNew
   from docS, docCountNcd
   where docS.docPrincId=docCountNcd.docPrincId
   --and   'S'='N'
  )
  order by 1,2,3,4,6,7,8


select doc.doc_anno annoDoc, doc.doc_numero numeroDoc, tipo.doc_tipo_code tipoDoc,
           'S'::varchar tipoColl,doc.doc_id docPrincId,
           subNcd.doc_id,
           subNcd.subdoc_id,
           rdoc.doc_importo_da_dedurre totaleImportoNcd
    from siac_t_doc doc, siac_t_subdoc subdoc, siac_r_subdoc_ordinativo_ts subdocTs,
         siac_t_ordinativo_ts ordts, siac_d_doc_tipo tipo,
         siac_r_doc rdoc, siac_d_relaz_tipo tipoRel,
         siac_t_doc docNcd, siac_t_subdoc subNcd, siac_d_doc_tipo tipoNcd
--    where ordts.ord_id=82944
--    where ordts.ord_id=83437
--  where ordts.ord_id=83430
  where ordts.ord_id=83440
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
    and   subNcd.doc_id=docNcd.doc_id
    and   tipoNcd.doc_tipo_id=docNcd.doc_tipo_id
    and   ordts.data_cancellazione is null and ordts.validita_fine is null
    and   subdocts.data_cancellazione is null AND subdocts.validita_fine is null
    and   subdoc.data_cancellazione is null and subdoc.validita_fine is null
    and   doc.data_cancellazione is null and doc.validita_fine is null
    and   subNcd.data_cancellazione is null and subNcd.validita_fine is null
    and   docNcd.data_cancellazione is null and docNcd.validita_fine is null
    and   rdoc.data_cancellazione is null and rdoc.validita_fine is null


---------- attuale
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
        null importoNcd,null numeroNcd,
        null importoRipartNcd
  from siac_t_doc doc, siac_t_subdoc subdoc, siac_r_subdoc_ordinativo_ts subdocTs,
       siac_t_ordinativo_ts ordts, siac_d_doc_tipo tipo,
       siac_r_doc_sog rsog, siac_t_soggetto sog
  where ordts.ord_id=83440
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
    select doc.doc_anno annoDoc, doc.doc_numero numeroDoc, tipo.doc_tipo_code tipoDoc,
           'S'::varchar tipoColl,doc.doc_id docPrincId,
           docNcd.doc_anno annoDocNcd, docNcd.doc_numero numeroDocNcd, tipoNcd.doc_tipo_code tipoDocNcd,
           lpad(extract('day' from docNcd.doc_data_emissione)::varchar,2,'0')||'/'||
           lpad(extract('month' from docNcd.doc_data_emissione)::varchar,2,'0')||'/'||
           extract('year' from docNcd.doc_data_emissione) dataDoc,
           sog.codice_fiscale codfiscDoc, sog.partita_iva partivaDoc,
           docNcd.doc_id docId,
           docNcd.pccuff_id pccuffId,
           subNcd.subdoc_data_scadenza datascadDoc,
           docNcd.siope_documento_tipo_id siopeDocTipoId,
           docNcd.doc_sdi_lotto_siope  siopeSdiLotto,
           docNcd.siope_documento_tipo_analogico_id siopeDocAnTipoId,
           sum(subdoc.subdoc_importo) importoDoc,
           0 importoSplitDoc,
           sum(subdoc.subdoc_importo_da_dedurre) importoNcd
    from siac_t_doc doc, siac_t_subdoc subdoc, siac_r_subdoc_ordinativo_ts subdocTs,
         siac_t_ordinativo_ts ordts, siac_d_doc_tipo tipo,
         siac_r_doc rdoc, siac_d_relaz_tipo tipoRel,
         siac_t_doc docNcd, siac_t_subdoc subNcd, siac_d_doc_tipo tipoNcd,
         siac_r_doc_sog rsog, siac_t_soggetto sog
  where ordts.ord_id=83440
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
    and   subNcd.doc_id=docNcd.doc_id
    and   tipoNcd.doc_tipo_id=docNcd.doc_tipo_id
    and   rsog.doc_id=docNcd.doc_id
    and   sog.soggetto_id=rsog.soggetto_id
    and   ordts.data_cancellazione is null and ordts.validita_fine is null
    and   subdocts.data_cancellazione is null AND subdocts.validita_fine is null
    and   subdoc.data_cancellazione is null and subdoc.validita_fine is null
    and   doc.data_cancellazione is null and doc.validita_fine is null
    and   subNcd.data_cancellazione is null and subNcd.validita_fine is null
    and   docNcd.data_cancellazione is null and docNcd.validita_fine is null
    and   rsog.data_cancellazione is null and rsog.validita_fine is null
    and   rdoc.data_cancellazione is null and rdoc.validita_fine is null
    and   sog.data_cancellazione is null
    group by  doc.doc_anno , doc.doc_numero , tipo.doc_tipo_code,doc.doc_id,
              docNcd.doc_anno , docNcd.doc_numero , tipoNcd.doc_tipo_code,
              lpad(extract('day' from docNcd.doc_data_emissione)::varchar,2,'0')||'/'||
              lpad(extract('month' from docNcd.doc_data_emissione)::varchar,2,'0')||'/'||
              extract('year' from docNcd.doc_data_emissione),
              sog.codice_fiscale, sog.partita_iva, docNcd.doc_id,docNcd.pccuff_id,subNcd.subdoc_data_scadenza,
              docNcd.siope_documento_tipo_id, docNcd.doc_sdi_lotto_siope,docNcd.siope_documento_tipo_analogico_id
   ),
   docCountNcd as
   (
    select doc.doc_anno annoDoc, doc.doc_numero numeroDoc, tipo.doc_tipo_code tipoDoc,
           'S'::varchar tipoColl,doc.doc_id docPrincId,
           count(*) numeroNcd
    from siac_t_doc doc, siac_t_subdoc subdoc, siac_r_subdoc_ordinativo_ts subdocTs,
         siac_t_ordinativo_ts ordts, siac_d_doc_tipo tipo,
         siac_r_doc rdoc, siac_d_relaz_tipo tipoRel,
         siac_t_doc docNcd, siac_t_subdoc subNcd, siac_d_doc_tipo tipoNcd
  where ordts.ord_id=83440
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
    and   subNcd.doc_id=docNcd.doc_id
    and   tipoNcd.doc_tipo_id=docNcd.doc_tipo_id
    and   ordts.data_cancellazione is null and ordts.validita_fine is null
    and   subdocts.data_cancellazione is null AND subdocts.validita_fine is null
    and   subdoc.data_cancellazione is null and subdoc.validita_fine is null
    and   doc.data_cancellazione is null and doc.validita_fine is null
    and   subNcd.data_cancellazione is null and subNcd.validita_fine is null
    and   docNcd.data_cancellazione is null and docNcd.validita_fine is null
    and   rdoc.data_cancellazione is null and rdoc.validita_fine is null
    group by doc.doc_anno , doc.doc_numero, tipo.doc_tipo_code ,doc.doc_id
   )
   select docS.*,
          docCountNcd.numeroNcd, round(docS.importoNcd/docCountNcd.numeroNcd,2) importoRipartNcd
   from docS, docCountNcd
   where docS.docPrincId=docCountNcd.docPrincId
   --and   escludiNCD='N'
  )
  order by 1,2,3,4,6,7,8









  select doc.doc_anno annoDoc, doc.doc_numero numeroDoc, tipo.doc_tipo_code tipoDoc,
           'S'::varchar tipoColl,doc.doc_id docPrincId,
           docNcd.doc_anno annoDocNcd, docNcd.doc_numero numeroDocNcd, tipoNcd.doc_tipo_code tipoDocNcd,
           lpad(extract('day' from docNcd.doc_data_emissione)::varchar,2,'0')||'/'||
           lpad(extract('month' from docNcd.doc_data_emissione)::varchar,2,'0')||'/'||
           extract('year' from docNcd.doc_data_emissione) dataDoc,
           sog.codice_fiscale codfiscDoc, sog.partita_iva partivaDoc,
           docNcd.doc_id docId,
           docNcd.pccuff_id pccuffId,
           subNcd.subdoc_data_scadenza datascadDoc,
           docNcd.siope_documento_tipo_id siopeDocTipoId,
           docNcd.doc_sdi_lotto_siope  siopeSdiLotto,
           docNcd.siope_documento_tipo_analogico_id siopeDocAnTipoId,
           subNCd.subdoc_id,
           subdoc.subdoc_importo importoDoc,
           0 importoSplitDoc,
           subdoc.subdoc_importo_da_dedurre importoNcd,
           rdoc.doc_importo_da_dedurre importoNcdNew
    from siac_t_doc doc, siac_t_subdoc subdoc, siac_r_subdoc_ordinativo_ts subdocTs,
         siac_t_ordinativo_ts ordts, siac_d_doc_tipo tipo,
         siac_r_doc rdoc, siac_d_relaz_tipo tipoRel,
         siac_t_doc docNcd, siac_t_subdoc subNcd, siac_d_doc_tipo tipoNcd,
         siac_r_doc_sog rsog, siac_t_soggetto sog
--    where ordts.ord_id=82944
--    where ordts.ord_id=83437
--    where ordts.ord_id=83430
  where ordts.ord_id=83440
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
    and   subNcd.doc_id=docNcd.doc_id
    and   tipoNcd.doc_tipo_id=docNcd.doc_tipo_id
    and   rsog.doc_id=docNcd.doc_id
    and   sog.soggetto_id=rsog.soggetto_id
    and   ordts.data_cancellazione is null and ordts.validita_fine is null
    and   subdocts.data_cancellazione is null AND subdocts.validita_fine is null
    and   subdoc.data_cancellazione is null and subdoc.validita_fine is null
    and   doc.data_cancellazione is null and doc.validita_fine is null
    and   subNcd.data_cancellazione is null and subNcd.validita_fine is null
    and   docNcd.data_cancellazione is null and docNcd.validita_fine is null
    and   rsog.data_cancellazione is null and rsog.validita_fine is null
    and   rdoc.data_cancellazione is null and rdoc.validita_fine is null
    and   sog.data_cancellazione is null
    group by  doc.doc_anno , doc.doc_numero , tipo.doc_tipo_code,doc.doc_id,
              docNcd.doc_anno , docNcd.doc_numero , tipoNcd.doc_tipo_code,
              lpad(extract('day' from docNcd.doc_data_emissione)::varchar,2,'0')||'/'||
              lpad(extract('month' from docNcd.doc_data_emissione)::varchar,2,'0')||'/'||
              extract('year' from docNcd.doc_data_emissione),
              sog.codice_fiscale, sog.partita_iva, docNcd.doc_id,docNcd.pccuff_id,subNcd.subdoc_data_scadenza,
              docNcd.siope_documento_tipo_id, docNcd.doc_sdi_lotto_siope,docNcd.siope_documento_tipo_analogico_id

  select s.*,
          r.*
  from siac_t_subdoc s, siac_r_subdoc_movgest_ts r
  where s.subdoc_id in (90291, 90294)
  and  r.subdoc_id=s.subdoc_id
  and  r.data_cancellazione is null
  and   r.validita_fine is null