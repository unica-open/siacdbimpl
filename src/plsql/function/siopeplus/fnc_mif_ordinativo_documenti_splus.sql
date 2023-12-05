/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

drop FUNCTION if exists siac.fnc_mif_ordinativo_documenti_splus( ordinativoId integer,
 													           numeroDocumenti integer,
                                                               tipiDocumento   varchar,
                                                               docAnalogico    varchar,
                                                               attrCodeDataScad varchar,
                                                               titoloCap        varchar,
                                                               codicePccUfficio varchar,
                                                   	           enteProprietarioId integer,
                                                               dataElaborazione timestamp,
                                                               dataFineVal timestamp);
                                                               
CREATE OR REPLACE FUNCTION siac.fnc_mif_ordinativo_documenti_splus( ordinativoId integer,
 													           numeroDocumenti integer,
                                                               tipiDocumento   varchar,
                                                               docAnalogico    varchar,
                                                               attrCodeDataScad varchar,
                                                               titoloCap        varchar,
                                                               codicePccUfficio varchar,
                                                   	           enteProprietarioId integer,
                                                               dataElaborazione timestamp,
                                                               dataFineVal timestamp)
RETURNS TABLE
(
    codice_ipa_ente_siope           varchar,
    tipo_documento_siope            varchar,
    tipo_documento_siope_a           varchar,
    identificativo_lotto_sdi_siope  varchar,
    tipo_documento_analogico_siope  varchar,
    codice_fiscale_emittente_siope  varchar,
    anno_emissione_fattura_siope    varchar,
    numero_fattura_siope  	        varchar,
    importo_siope                   varchar,
    importo_siope_split             varchar, -- 22.12.2017 Sofia siac-5665
    data_scadenza_pagam_siope       varchar,
    motivo_scadenza_siope           varchar,
    natura_spesa_siope              varchar

 ) AS
$body$
DECLARE

strMessaggio varchar(1500):=null;
documentiRec record;


motivoScadenza    varchar(500):=null;
dataScadDopoSosp  varchar(500):=null;
tipoDocAnalogico  varchar(500):=null;
codFiscElettronico varchar(100):=null;

DOC_TIPO_ALG      CONSTANT varchar:='ALG';

numeroDocs integer:=1;

tipoDocFPR   varchar(10):=null;
tipoGruppoDocFAT   varchar(10):=null;
tipoGruppoDocNCD   varchar(10):=null;

-- 29.02.2023 Sofia Jira SIAC-8880
tipoDocNTE   varchar(10):=null;

docPrincId integer:=null;
countNcdCalc integer:=0;
importoNcd numeric:=0;
importoDoc numeric:=0;
importoNcdRipart numeric:=0;

-- 15.01.2018 Sofia JIRA siac-5765
codiceFiscaleDef varchar(50):=null;

-- 26.02.2018 Sofia JIRA siac-5849
escludiNCD VARCHAR(10):=null;

BEGIN

 strMessaggio:='Lettura documenti collegati.';

 codice_ipa_ente_siope:=null;
 tipo_documento_siope:=null;
 tipo_documento_siope_a:=null;

 identificativo_lotto_sdi_siope:=null;
 tipo_documento_analogico_siope:=null;
 codice_fiscale_emittente_siope:=null;
 anno_emissione_fattura_siope:=null;
 numero_fattura_siope:=null;
 importo_siope:=null;
 importo_siope_split:=null; -- 22.12.2017 Sofia siac-5665
 data_scadenza_pagam_siope:=null;
 motivo_scadenza_siope:=null;
 natura_spesa_siope:=null;


 strMessaggio:='Lettura documenti collegati.Inizio ciclo lettura.';
 --raise notice 'strMessaggio =%',strMessaggio;

 tipoDocFPR:=trim (both ' ' from split_part(tipiDocumento,'|',1));

 tipoGruppoDocFAT:=trim (both ' ' from split_part(tipiDocumento,'|',2));
 tipoGruppoDocFAT:=trim (both ' ' from split_part(tipoGruppoDocFAT,',',1));


 tipoGruppoDocNCD:=trim (both ' ' from split_part(tipiDocumento,'|',2));
 tipoGruppoDocNCD:=trim (both ' ' from split_part(tipoGruppoDocNCD,',',2));

 -- 29.03.2023 Sofia Jira SIAC-8880
 tipoDocNTE:=trim (both ' ' from split_part(tipiDocumento,'|',3));


 escludiNCD:=trim (both ' ' from split_part(titoloCap,'|',2));
 if escludiNCD is not null and escludiNCD!='' and escludiNCD='S' then
 	   -- esclusione note di credito da estrazione documenti
       -- per ordinativi di entrata SPLIT
 else
       escludiNCD:='N';
 end if;
 titoloCap:=trim(both ' ' from split_part(titoloCap,'|',1));



 raise notice 'tipoDocFPR =%',tipoDocFPR;
 raise notice 'tipoGruppoDocFAT =%',tipoGruppoDocFAT;
 raise notice 'tipoGruppoDocNCD =%',tipoGruppoDocNCD;
 raise notice 'tipoDocNTE =%',tipoDocNTE;

 /* 15.01.2018 Sofia JIRA SIAC-5765 */

 raise notice 'docAnalogico=%',docAnalogico;
 codiceFiscaleDef:=trim (both ' ' from split_part(docAnalogico,'|',2));
 docAnalogico:=trim (both ' ' from split_part(docAnalogico,'|',1));

 raise notice 'docAnalogico=%',docAnalogico;
 raise notice 'codiceFiscaleDef=%',codiceFiscaleDef;


/* for documentiRec in
 ( select doc.doc_anno annoDoc, doc.doc_numero numeroDoc, tipo.doc_tipo_code tipoDoc,
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
          sum(subdoc.subdoc_importo) importoDoc
   from siac_t_doc doc, siac_t_subdoc subdoc, siac_r_subdoc_ordinativo_ts subdocTs,
        siac_t_ordinativo_ts ordts, siac_d_doc_tipo tipo,
        siac_r_doc_sog rsog, siac_t_soggetto sog
   where ordts.ord_id=ordinativoId
   and   subdocts.ord_ts_id=ordts.ord_ts_id
   and   subdoc.subdoc_id=subdocts.subdoc_id
   and   doc.doc_id=subdoc.doc_id
   and   tipo.doc_tipo_id=doc.doc_tipo_id
--   and   fnc.isCommerciale=true
   and   fnc_mif_isDocumentoCommerciale_splus(doc.doc_id,tipoDocFPR,tipoGruppoDocFAT,tipoGruppoDocNCD)=true -- 'FPR','FAT','NCD')=true
   and   tipo.doc_tipo_code!=DOC_TIPO_ALG
   and   rsog.doc_id=doc.doc_id
   and   sog.soggetto_id=rsog.soggetto_id
   and   ordts.data_cancellazione is null and ordts.validita_fine is null
   and   subdocts.data_cancellazione is null AND subdocts.validita_fine is null
   and   subdoc.data_cancellazione is null and subdoc.validita_fine is null
   and   doc.data_cancellazione is null and doc.validita_fine is null
   and   tipo.data_cancellazione is null
   and   rsog.data_cancellazione is null and rsog.validita_fine is null
   and   sog.data_cancellazione is null
   and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
   and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione))
   group by doc.doc_anno , doc.doc_numero , tipo.doc_tipo_code,
          lpad(extract('day' from doc.doc_data_emissione)::varchar,2,'0')||'/'||
          lpad(extract('month' from doc.doc_data_emissione)::varchar,2,'0')||'/'||
          extract('year' from doc.doc_data_emissione),
          sog.codice_fiscale, sog.partita_iva, doc.doc_id,doc.pccuff_id,subdoc.subdoc_data_scadenza,
          doc.siope_documento_tipo_id, doc.doc_sdi_lotto_siope,doc.siope_documento_tipo_analogico_id
   union
   select docNcd.doc_anno annoDoc, docNcd.doc_numero numeroDoc, tipoNcd.doc_tipo_code tipoDoc,
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
          sum(subdoc.subdoc_importo_da_dedurre) importoDoc -- somm subdoc_importo_da_dedurre / numero di note collegate
   from siac_t_doc doc, siac_t_subdoc subdoc, siac_r_subdoc_ordinativo_ts subdocTs,
        siac_t_ordinativo_ts ordts, siac_d_doc_tipo tipo,
        siac_r_doc rdoc, siac_d_relaz_tipo tipoRel,
        siac_t_doc docNcd, siac_t_subdoc subNcd, siac_d_doc_tipo tipoNcd,
        siac_r_doc_sog rsog, siac_t_soggetto sog
   where ordts.ord_id=ordinativoId
   and   subdocts.ord_ts_id=ordts.ord_ts_id
   and   subdoc.subdoc_id=subdocts.subdoc_id
   and   doc.doc_id=subdoc.doc_id
   and   tipo.doc_tipo_id=doc.doc_tipo_id
   and   fnc_mif_isDocumentoCommerciale_splus(doc.doc_id,tipoDocFPR,tipoGruppoDocFAT,tipoGruppoDocNCD)=true
   and   tipo.doc_tipo_code!=DOC_TIPO_ALG
   and   rdoc.doc_id_da=doc.doc_id
   and   docncd.doc_id=rdoc.doc_id_a
   and   tipoRel.relaz_tipo_id=rdoc.relaz_tipo_id
   and   tipoRel.relaz_tipo_code=tipoGruppoDocNCD
   and   fnc_mif_isDocumentoCommerciale_splus(docNcd.doc_id,tipoDocFPR,tipoGruppoDocFAT,tipoGruppoDocNCD)=true
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
   group by docNcd.doc_anno , docNcd.doc_numero , tipoNcd.doc_tipo_code,
          lpad(extract('day' from docNcd.doc_data_emissione)::varchar,2,'0')||'/'||
          lpad(extract('month' from docNcd.doc_data_emissione)::varchar,2,'0')||'/'||
          extract('year' from docNcd.doc_data_emissione),
          sog.codice_fiscale, sog.partita_iva, docNcd.doc_id,docNcd.pccuff_id,subNcd.subdoc_data_scadenza,
          docNcd.siope_documento_tipo_id, docNcd.doc_sdi_lotto_siope,docNcd.siope_documento_tipo_analogico_id
   order by 3, 1,2
 )*/
 for documentiRec in
 (
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
        null importoDaDedurre, -- 16.05.2018 Sofia siac-6137
        null importoNcd,       -- 02.05.2018 Sofia siac-6137
        null numeroNcd,
        null importoRipartNcd     -- 02.05.2018 Sofia siac-6137
  from siac_t_doc doc, siac_t_subdoc subdoc, siac_r_subdoc_ordinativo_ts subdocTs,
       siac_t_ordinativo_ts ordts, siac_d_doc_tipo tipo,
       siac_r_doc_sog rsog, siac_t_soggetto sog
  where ordts.ord_id=ordinativoId
  and   subdocts.ord_ts_id=ordts.ord_ts_id
  and   subdoc.subdoc_id=subdocts.subdoc_id
  and   doc.doc_id=subdoc.doc_id
  and   tipo.doc_tipo_id=doc.doc_tipo_id
--  and   fnc_mif_isDocumentoCommerciale_splus(doc.doc_id,tipoDocFPR,tipoGruppoDocFAT,tipoGruppoDocNCD)=TRUE -- 29.03.2023 Sofia Jira SIAC-8880
  and   fnc_mif_isDocumentoCommerciale_splus(doc.doc_id,tipoDocFPR,tipoGruppoDocFAT,tipoGruppoDocNCD,tipoDocNTE)=true -- 29.03.2023 Sofia Jira SIAC-8880
  and   tipo.doc_tipo_code!=DOC_TIPO_ALG
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
--           subNcd.subdoc_data_scadenza datascadDoc, -- 08.05.2018 Sofia siac-6137
           docNcd.doc_data_emissione   datascadDoc,   -- 08.05.2018 Sofia siac-6137
           docNcd.siope_documento_tipo_id siopeDocTipoId,
           docNcd.doc_sdi_lotto_siope  siopeSdiLotto,
           docNcd.siope_documento_tipo_analogico_id siopeDocAnTipoId,
           sum(subdoc.subdoc_importo) importoDoc,
           0 importoSplitDoc,
           sum(subdoc.subdoc_importo_da_dedurre) importoDaDedurre, -- 16.05.2018 Sofia siac-6137
           sum(rdoc.doc_importo_da_dedurre) importoNcd          -- 02.05.2018 Sofia siac-6137
    from siac_t_doc doc, siac_t_subdoc subdoc, siac_r_subdoc_ordinativo_ts subdocTs,
         siac_t_ordinativo_ts ordts, siac_d_doc_tipo tipo,
         siac_r_doc rdoc, siac_d_relaz_tipo tipoRel,
--         siac_t_doc docNcd, siac_t_subdoc subNcd, siac_d_doc_tipo tipoNcd, -- 08.05.2018 Sofia siac-6137
         siac_t_doc docNcd, siac_d_doc_tipo tipoNcd, -- 08.05.2018 Sofia siac-6137
         siac_r_doc_sog rsog, siac_t_soggetto sog
    where ordts.ord_id=ordinativoId
    and   subdocts.ord_ts_id=ordts.ord_ts_id
    and   subdoc.subdoc_id=subdocts.subdoc_id
    and   doc.doc_id=subdoc.doc_id
    and   tipo.doc_tipo_id=doc.doc_tipo_id
--    and   fnc_mif_isDocumentoCommerciale_splus(doc.doc_id,tipoDocFPR,tipoGruppoDocFAT,tipoGruppoDocNCD)=true  -- 29.03.2023 Sofia Jira SIAC-8880
    and   fnc_mif_isDocumentoCommerciale_splus(doc.doc_id,tipoDocFPR,tipoGruppoDocFAT,tipoGruppoDocNCD,tipoDocNTE)=true     -- 29.03.2023 Sofia Jira SIAC-8880
    and   tipo.doc_tipo_code!=DOC_TIPO_ALG
    and   rdoc.doc_id_da=doc.doc_id
    and   docncd.doc_id=rdoc.doc_id_a
    and   tipoRel.relaz_tipo_id=rdoc.relaz_tipo_id
    and   tipoRel.relaz_tipo_code=tipoGruppoDocNCD
--    and   fnc_mif_isDocumentoCommerciale_splus(docNcd.doc_id,tipoDocFPR,tipoGruppoDocFAT,tipoGruppoDocNCD)=true -- 29.03.2023 Sofia Jira SIAC-8880
    and   fnc_mif_isDocumentoCommerciale_splus(docNcd.doc_id,tipoDocFPR,tipoGruppoDocFAT,tipoGruppoDocNCD,tipoDocNTE)=true     -- 29.03.2023 Sofia Jira SIAC-8880    
--    and   subNcd.doc_id=docNcd.doc_id -- 08.05.2018 Sofia siac-6137
    and   tipoNcd.doc_tipo_id=docNcd.doc_tipo_id
    and   rsog.doc_id=docNcd.doc_id
    and   sog.soggetto_id=rsog.soggetto_id
    and   ordts.data_cancellazione is null and ordts.validita_fine is null
    and   subdocts.data_cancellazione is null AND subdocts.validita_fine is null
    and   subdoc.data_cancellazione is null and subdoc.validita_fine is null
    and   doc.data_cancellazione is null and doc.validita_fine is null
--    and   subNcd.data_cancellazione is null and subNcd.validita_fine is null -- 08.05.2018 Sofia siac-6137
    and   docNcd.data_cancellazione is null and docNcd.validita_fine is null
    and   rsog.data_cancellazione is null and rsog.validita_fine is null
    and   rdoc.data_cancellazione is null and rdoc.validita_fine is null
    and   sog.data_cancellazione is null
    group by  doc.doc_anno , doc.doc_numero , tipo.doc_tipo_code,doc.doc_id,
              docNcd.doc_anno , docNcd.doc_numero , tipoNcd.doc_tipo_code,
              lpad(extract('day' from docNcd.doc_data_emissione)::varchar,2,'0')||'/'||
              lpad(extract('month' from docNcd.doc_data_emissione)::varchar,2,'0')||'/'||
              extract('year' from docNcd.doc_data_emissione),
--              sog.codice_fiscale, sog.partita_iva, docNcd.doc_id,docNcd.pccuff_id,subNcd.subdoc_data_scadenza, -- 08.05.2018 Sofia siac-6137
			  sog.codice_fiscale, sog.partita_iva, docNcd.doc_id,docNcd.pccuff_id,docNcd.doc_data_emissione,-- 08.05.2018 Sofia siac-6137
              docNcd.siope_documento_tipo_id, docNcd.doc_sdi_lotto_siope,docNcd.siope_documento_tipo_analogico_id
   ),
   docCountNcd as
   (
    select doc.doc_anno annoDoc, doc.doc_numero numeroDoc, tipo.doc_tipo_code tipoDoc,
           'S'::varchar tipoColl,doc.doc_id docPrincId,
           sum(rdoc.doc_importo_da_dedurre) totaleImportoNcd, -- 02.05.2018 Sofia siac-6137
           count(*) numeroNcd
    from siac_t_doc doc, siac_t_subdoc subdoc, siac_r_subdoc_ordinativo_ts subdocTs,
         siac_t_ordinativo_ts ordts, siac_d_doc_tipo tipo,
         siac_r_doc rdoc, siac_d_relaz_tipo tipoRel,
--         siac_t_doc docNcd, siac_t_subdoc subNcd, siac_d_doc_tipo tipoNcd -- 08.05.2018 Sofia siac-6137
         siac_t_doc docNcd, siac_d_doc_tipo tipoNcd -- 08.05.2018 Sofia siac-6137
    where ordts.ord_id=ordinativoId
    and   subdocts.ord_ts_id=ordts.ord_ts_id
    and   subdoc.subdoc_id=subdocts.subdoc_id
    and   doc.doc_id=subdoc.doc_id
    and   tipo.doc_tipo_id=doc.doc_tipo_id
--    and   fnc_mif_isDocumentoCommerciale_splus(doc.doc_id,tipoDocFPR,tipoGruppoDocFAT,tipoGruppoDocNCD)=true -- 29.03.2023 Sofia Jira SIAC-8880
    and   fnc_mif_isDocumentoCommerciale_splus(doc.doc_id,tipoDocFPR,tipoGruppoDocFAT,tipoGruppoDocNCD,tipoDocNTE)=true    -- 29.03.2023 Sofia Jira SIAC-8880
    and   tipo.doc_tipo_code!=DOC_TIPO_ALG
    and   rdoc.doc_id_da=doc.doc_id
    and   docncd.doc_id=rdoc.doc_id_a
    and   tipoRel.relaz_tipo_id=rdoc.relaz_tipo_id
    and   tipoRel.relaz_tipo_code=tipoGruppoDocNCD
--    and   fnc_mif_isDocumentoCommerciale_splus(docNcd.doc_id,tipoDocFPR,tipoGruppoDocFAT,tipoGruppoDocNCD)=true  -- 29.03.2023 Sofia Jira SIAC-8880
    and   fnc_mif_isDocumentoCommerciale_splus(docNcd.doc_id,tipoDocFPR,tipoGruppoDocFAT,tipoGruppoDocNCD,tipoDocNTE)=true     -- 29.03.2023 Sofia Jira SIAC-8880
--    and   subNcd.doc_id=docNcd.doc_id -- 08.05.2018 Sofia siac-6137
    and   tipoNcd.doc_tipo_id=docNcd.doc_tipo_id
    and   ordts.data_cancellazione is null and ordts.validita_fine is null
    and   subdocts.data_cancellazione is null AND subdocts.validita_fine is null
    and   subdoc.data_cancellazione is null and subdoc.validita_fine is null
    and   doc.data_cancellazione is null and doc.validita_fine is null
--    and   subNcd.data_cancellazione is null and subNcd.validita_fine is null -- 08.05.2018 Sofia siac-6137
    and   docNcd.data_cancellazione is null and docNcd.validita_fine is null
    and   rdoc.data_cancellazione is null and rdoc.validita_fine is null
    group by doc.doc_anno , doc.doc_numero, tipo.doc_tipo_code ,doc.doc_id
   )
   select docS.*,
          docCountNcd.numeroNcd,
--          round(docS.importoDoc/docCountNcd.numeroNcd,2) importoRipartNcd, -- 02.05.2018 Sofia siac-6137
          round((docs.importoNcd*docS.importoDaDedurre)/docCountNcd.totaleImportoNcd,2) importoRipartNcd -- 16.05.2018 Sofia siac-6137
   from docS, docCountNcd
   where docS.docPrincId=docCountNcd.docPrincId
   and   escludiNCD='N'
  )
  order by 1,2,3,4,6,7,8
 )
 loop

    strMessaggio:='Lettura dati documento doc_id='||documentiRec.docId||'.';
    raise notice 'strMessaggio =%',strMessaggio;

    codice_ipa_ente_siope:=null;          -- ok siac_t_doc.pccuff_id
    tipo_documento_siope:=null;           -- ok siac_t_doc.siope_documento_tipo_id
    tipo_documento_siope_a:=null;         -- ok siac_t_doc.siope_documento_tipo_id
    identificativo_lotto_sdi_siope:=null; -- ok siac_t_doc.doc_sdi_lotto_siope
    tipo_documento_analogico_siope:=null; -- ok solo per doc ANALOGICO doc.siope_documento_tipo_analogico_id
    codice_fiscale_emittente_siope:=null; -- ok
    anno_emissione_fattura_siope:=null;   -- ok
    numero_fattura_siope:=null;           -- ok
    importo_siope:=null;                  -- ok
    importo_siope_split:=null;            -- ok -- 22.12.2017 Sofia siac-5665
    data_scadenza_pagam_siope:=null;      -- dataScadenzaDopoSospensione ok
    motivo_scadenza_siope:=null;          -- ok siac_t_subdoc.siope_scadenza_motivo_id
    natura_spesa_siope:=null;             -- CORRENTE/CAPITALE da capitolo

	motivoScadenza:=null;
    dataScadDopoSosp:=null;
    tipoDocAnalogico:=null;
    codFiscElettronico:=null;

--    raise notice 'strMessaggio =%',strMessaggio;


    if documentiRec.pccuffId is not null then
        strMessaggio:='Lettura dati documento doc_id='||documentiRec.docId||'.'||' Lettura codice ufficio [siac_d_pcc_ufficio].';

	--	 raise notice 'strMessaggio 2 =%',strMessaggio;

    	select pcc.pccuff_code into codice_ipa_ente_siope
        from siac_d_pcc_ufficio pcc
        where pcc.pccuff_id=documentiRec.pccuffId;
    else
        if codicePccUfficio is not null then
        	codice_ipa_ente_siope:=codicePccUfficio;
        end if;
    end if;

    if documentiRec.siopeDocTipoId is not null then
    	strMessaggio:='Lettura dati documento doc_id='||documentiRec.docId||'.'||' Lettura tipo documento siope [siac_d_siope_documento_tipo].';
		 --raise notice 'strMessaggio 3 =%',strMessaggio;

        select upper(tipo.siope_documento_tipo_desc_bnkit) into tipoDocAnalogico
        from siac_d_siope_documento_tipo tipo
        where tipo.siope_documento_tipo_id=documentiRec.siopeDocTipoId;

        if tipoDocAnalogico is not null   then
         if tipoDocAnalogico=docAnalogico then
        	  tipo_documento_siope_a:=tipoDocAnalogico; -- ANALOGICO
         else
              tipo_documento_siope:=tipoDocAnalogico;   -- ELETTRONCIO

              if documentiRec.siopeSdiLotto is not null then
	              identificativo_lotto_sdi_siope:=documentiRec.siopeSdiLotto;
              end if;

         end if;
        end if;
    end if;

    -- se documento analogico
    if tipo_documento_siope_a is not null and
       documentiRec.siopeDocAnTipoId is not null then

       strMessaggio:='Lettura dati documento doc_id='||documentiRec.docId||'.'||' Lettura tipo documento analogico siope [siac_d_siope_documento_tipo_analogico].';
  	   --raise notice 'strMessaggio 4 =%',strMessaggio;

       select upper(tipo.siope_documento_tipo_analogico_desc_bnkit) into tipo_documento_analogico_siope
       from siac_d_siope_documento_tipo_analogico tipo
       where tipo.siope_documento_tipo_analogico_id=documentiRec.siopeDocAnTipoId;

      -- 23.01.2018 Sofia JIRA siac-5765
	  if documentiRec.codfiscDoc is not null and documentiRec.codfiscDoc!='' then
		  codice_fiscale_emittente_siope:=documentiRec.codfiscDoc;
      else
      	  codice_fiscale_emittente_siope:=codiceFiscaleDef;
      end if;
      if documentiRec.tipoColl='P' then
	     anno_emissione_fattura_siope:=documentiRec.annoDoc::varchar;
      else
         anno_emissione_fattura_siope:=documentiRec.annoDocNcd::varchar;
      end if;
    end if;


   	if documentiRec.docPrincId!=coalesce(docPrincId,-1) then
		docPrincId:=documentiRec.docPrincId;
        importoDoc:=documentiRec.importoDoc;
        countNcdCalc:=1;
    end if;
    raise notice 'docPrincId=%',docPrincId;
    raise notice 'importoDoc=%',importoDoc;
    raise notice 'importoNcd=%',importoNcd;
    raise notice 'countNcdCalc=%',countNcdCalc;
    raise notice 'tipoColl=%',documentiRec.tipoColl;
    raise notice 'importoNcdRipart=%',importoNcdRipart;
    raise notice 'documentiRec.importoDoc=%',documentiRec.importoDoc;
    raise notice 'documentiRec.importoNcd=%',documentiRec.importoNcd;
    raise notice 'documentiRec.importoRipartNcd=%',documentiRec.importoRipartNcd;
    raise notice 'documentiRec.importoSplitDoc=%',documentiRec.importoSplitDoc;

    if documentiRec.tipoColl='S' then
        importoNcd:=documentiRec.importoNcd;
        importoNcdRipart:=importoNcdRipart+documentiRec.importoRipartNcd;
		countNcdCalc:=countNcdCalc+1;
-- 16.05.2018 Sofia siac-6137
/*        if countNcdCalc>documentiRec.numeroNcd then
/*        	if importoNcdRipart!=importoNcd then
				documentiRec.importoRipartNcd:=documentiRec.importoRipartNcd+(importoNcd-importoNcdRipart);
            end if;*/
            if importoDoc!=importoNcdRipart then
				documentiRec.importoRipartNcd:=documentiRec.importoRipartNcd+(importoDoc-importoNcdRipart);
            end if;
        end if;*/

        strMessaggio:='Lettura dataScadenza per NCD doc_id='||documentiRec.docId||'.';
  	    raise notice 'strMessaggio dataScad NCD =%',strMessaggio;

        documentiRec.datascadDoc:=null;
        select  sub.subdoc_data_scadenza into documentiRec.datascadDoc
        from siac_t_subdoc sub
        where sub.doc_id=documentiRec.docId
        and   sub.subdoc_data_scadenza is not null
        and   sub.data_cancellazione is null
        and   sub.validita_fine is null
        limit 1;

    end if;

    raise notice 'documentiRec.datascadDoc=%',documentiRec.datascadDoc;

    if documentiRec.tipoColl='P' then
        numero_fattura_siope:=documentiRec.numeroDoc;
	    importo_siope:=documentiRec.importoDoc::varchar;
        importo_siope_split:=documentiRec.importoSplitDoc::varchar; -- 22.12.2017 Sofia siac-5665
    else
        numero_fattura_siope:=documentiRec.numeroDocNcd;
--    	importo_siope:=(-documentiRec.importoRipartNcd)::varchar; -- 01.02.2018 Sofia siac-5849
       	importo_siope:=(-documentiRec.importoRipartNcd)::varchar; -- 01.02.2018 Sofia siac-5849

    end if;

    -- se importo=0  non resistuisco dati
    if importo_siope::numeric =0 then
    	continue;
    end if;
--    		 raise notice 'strMessaggio 3 =%',strMessaggio;


    -- se documento elettronico vado a cercare il codice fiscale del documento FEL
/*    if tipo_documento_siope is not null then

        strMessaggio:='Lettura dati documento doc_id='||documentiRec.docId||'.'||' Lettura tipo documento analogico siope [siac_d_siope_documento_tipo_analogico].';

        select presta.codice_prestatore into codFiscElettronico
	    from siac_r_doc_sirfel rs,
	         sirfel_t_fattura fel,sirfel_t_prestatore presta
		where rs.doc_id=documentiRec.docId
		and   fel.id_fattura=rs.id_fattura
	    and   presta.id_prestatore=fel.id_prestatore
		and   rs.data_cancellazione is null
		and   rs.validita_fine is null;

        if codFiscElettronico is not null and
           codFiscElettronico!=codice_fiscale_emittente_siope then
           codice_fiscale_emittente_siope:=codFiscElettronico;
        end if;
    end if;
*/

--		 raise notice 'strMessaggio 4 =%',strMessaggio;

    strMessaggio:='Lettura dati documento doc_id='||documentiRec.docId||'.'||' Lettura motivo scadenza.';
-- raise notice 'strMessaggio =%',strMessaggio;

	select  distinct upper(mot.siope_scadenza_motivo_desc_bnkit)  into motivoScadenza
    from siac_t_subdoc sub, siac_d_siope_scadenza_motivo mot
	where sub.doc_id=documentiRec.docId
    and   sub.siope_scadenza_motivo_id is not null
    and   mot.siope_scadenza_motivo_id=sub.siope_scadenza_motivo_id
	and   sub.data_cancellazione is null
	and   sub.validita_fine is null
    limit 1;

    if coalesce(motivoScadenza,'')!='' then
    	motivo_scadenza_siope:=motivoScadenza;
    end if;

    strMessaggio:='Lettura dati documento doc_id='||documentiRec.docId||'.'||' Lettura data scadenza dopo sospensione.';
	select rattr.testo data_scadenza_dopo_sosp into dataScadDopoSosp
	from siac_t_subdoc sub ,siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts ord,
	     siac_r_subdoc_attr rattr, siac_t_attr attr
	where sub.doc_id=documentiRec.docId
	and   rord.subdoc_id=sub.subdoc_id
	and   ord.ord_ts_id=rord.ord_ts_id
	and   ord.ord_id=ordinativoId
	and   rattr.subdoc_id=sub.subdoc_id
	and   attr.attr_id=rattr.attr_id
	and   attr.attr_code=attrCodeDataScad
	and   rattr.testo is not null
	and   sub.data_cancellazione is null
	and   sub.validita_fine is null
	and   rord.data_cancellazione is null
	and   rord.validita_fine  is null
	and   ord.data_cancellazione is null
	and   ord.validita_fine is null
	and   rattr.data_cancellazione  is null
	and   rattr.validita_fine is null
    limit 1;

    if coalesce(dataScadDopoSosp,'')!='' then
    	data_scadenza_pagam_siope:=substring(dataScadDopoSosp,7,4)||'-'||
        						   substring(dataScadDopoSosp,4,2)||'-'||
                                   substring(dataScadDopoSosp,1,2);
    else
    	if documentiRec.datascadDoc is not null  then
        	data_scadenza_pagam_siope:=extract('year' from documentiRec.datascadDoc)::varchar||'-'||
            					       lpad(extract('month' from documentiRec.datascadDoc)::varchar,2,'0')||'-'||
					                   lpad(extract('day' from documentiRec.datascadDoc)::varchar,2,'0');
        end if;
    end if;
    natura_spesa_siope:=titoloCap;


    exit when numeroDocs>numeroDocumenti;

	return next;

    numeroDocs:=numeroDocs+1;
 end loop;

 --raise notice 'numeroDocs %',numeroDocs;

 return;


exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',coalesce(strMessaggio,'')||' '||coalesce(substring(upper(SQLERRM) from 1 for 1000),'');
        return;
    when TOO_MANY_ROWS THEN
        RAISE EXCEPTION '% Diverse righe lette.',coalesce(strMessaggio,'');
        return;
   when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',coalesce(strMessaggio,'');
        return;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',coalesce(strMessaggio,''),SQLSTATE,substring(SQLERRM from 1 for 1000);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


alter FUNCTION siac.fnc_mif_ordinativo_documenti_splus (  integer,  integer, varchar, varchar, varchar,varchar,varchar,integer,timestamp,timestamp) owner to siac;                                                              