/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-5894 - Sofia INIZIO - 02.02.2018

CREATE OR REPLACE FUNCTION fnc_mif_ordinativo_documenti_splus( ordinativoId integer,
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

docPrincId integer:=null;
countNcdCalc integer:=0;
importoNcd numeric:=0;
importoDoc numeric:=0;
importoNcdRipart numeric:=0;

-- 15.01.2018 Sofia JIRA siac-5765
codiceFiscaleDef varchar(50):=null;

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




 --raise notice 'tipoDocFPR =%',tipoDocFPR;
 --raise notice 'tipoGruppoDocFAT =%',tipoGruppoDocFAT;
 --raise notice 'tipoGruppoDocNCD =%',tipoGruppoDocNCD;

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
        null importoNcd,null numeroNcd,
        null importoRipartNcd
  from siac_t_doc doc, siac_t_subdoc subdoc, siac_r_subdoc_ordinativo_ts subdocTs,
       siac_t_ordinativo_ts ordts, siac_d_doc_tipo tipo,
       siac_r_doc_sog rsog, siac_t_soggetto sog
  where ordts.ord_id=ordinativoId
  and   subdocts.ord_ts_id=ordts.ord_ts_id
  and   subdoc.subdoc_id=subdocts.subdoc_id
  and   doc.doc_id=subdoc.doc_id
  and   tipo.doc_tipo_id=doc.doc_tipo_id
  and   fnc_mif_isDocumentoCommerciale_splus(doc.doc_id,tipoDocFPR,tipoGruppoDocFAT,tipoGruppoDocNCD)=true
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
    /*raise notice 'docPrincId=%',docPrincId;
    raise notice 'importoNcd=%',importoNcd;
    raise notice 'countNcdCalc=%',countNcdCalc;
    raise notice 'tipoColl=%',documentiRec.tipoColl;
    raise notice 'importoNcdRipart=%',importoNcdRipart;
    raise notice 'documentiRec.importoRipartNcd=%',documentiRec.importoRipartNcd;
    raise notice 'documentiRec.importoSplitDoc=%',documentiRec.importoSplitDoc;*/

    if documentiRec.tipoColl='S' then
        importoNcd:=documentiRec.importoNcd;
        importoNcdRipart:=importoNcdRipart+documentiRec.importoRipartNcd;
		countNcdCalc:=countNcdCalc+1;
        if countNcdCalc>documentiRec.numeroNcd then
        	if importoNcdRipart!=importoNcd then
				documentiRec.importoRipartNcd:=documentiRec.importoRipartNcd+(importoNcd-importoNcdRipart);
            end if;
        end if;
    end if;



    if documentiRec.tipoColl='P' then
        numero_fattura_siope:=documentiRec.numeroDoc;
	    importo_siope:=documentiRec.importoDoc::varchar;
        importo_siope_split:=documentiRec.importoSplitDoc::varchar; -- 22.12.2017 Sofia siac-5665
    else
        numero_fattura_siope:=documentiRec.numeroDocNcd;
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

-- SIAC-5894 - Sofia INIZIO - 02.02.2018

-- SIAC-5778 INIZIO
CREATE OR REPLACE FUNCTION siac."BILR171_allegato_fpv_previsione_con_dati_gestione" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  missione_code varchar,
  missione_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  importi_capitoli numeric,
  spese_impegnate numeric,
  spese_impegnate_anno1 numeric,
  spese_impegnate_anno2 numeric,
  spese_impegnate_anno_succ numeric,
  importo_avanzo numeric,
  importo_avanzo_anno1 numeric,
  importo_avanzo_anno2 numeric,
  importo_avanzo_anno_succ numeric,
  elem_id integer,
  anno_esercizio varchar
) AS
$body$
DECLARE

RTN_MESSAGGIO text;
bilancio_id integer;
bilancio_id_prec integer;
cod_fase_operativa varchar;
anno_esercizio varchar;
anno_esercizio_prec varchar;
annoimpimpegni_int integer;

BEGIN

/*Se la fase di bilancio e' Previsione allora l''anno di esercizio e il bilancio id saranno
quelli di p_anno-1 per tutte le colonne. 

Se la fase di bilancio e' Esercizio Provvisorio allora l''anno di esercizio e il bilancio id saranno
quelli di p_anno per tutte le colonne tranne quella relativa agli iporti dei capitolo (colonna a).
In questo caso l''anno di esercizio e il bilancio id saranno quelli di p_anno-1.*/

RTN_MESSAGGIO := 'select 1'; 

bilancio_id := null;
bilancio_id_prec := null;

select bil.bil_id, fase_operativa.fase_operativa_code
into   bilancio_id, cod_fase_operativa
from  siac_d_fase_operativa fase_operativa, 
      siac_r_bil_fase_operativa bil_fase_operativa, 
      siac_t_bil bil, 
      siac_t_periodo periodo
where fase_operativa.fase_operativa_id = bil_fase_operativa.fase_operativa_id
and   bil_fase_operativa.bil_id = bil.bil_id
and   periodo.periodo_id = bil.periodo_id
and   fase_operativa.fase_operativa_code in ('P','E','G') -- SIAC-5778 Aggiunto G
and   bil.ente_proprietario_id = p_ente_prop_id
and   periodo.anno = p_anno
and   fase_operativa.data_cancellazione is null
and   bil_fase_operativa.data_cancellazione is null 
and   bil.data_cancellazione is null 
and   periodo.data_cancellazione is null;
 
if cod_fase_operativa = 'P' then
  
  anno_esercizio := ((p_anno::integer)-1)::varchar;   

  select a.bil_id 
  into bilancio_id 
  from siac_t_bil a,siac_t_periodo b
  where a.ente_proprietario_id = p_ente_prop_id 
  and b.periodo_id = a.periodo_id
  and b.anno = anno_esercizio;
  
elsif cod_fase_operativa in ('E','G') then

  anno_esercizio := p_anno; 
  
end if;

-- anno_esercizio_prec := ((anno_esercizio::integer)-1)::varchar;
anno_esercizio_prec := ((p_anno::integer)-1)::varchar;

select a.bil_id
into bilancio_id_prec 
from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id = p_ente_prop_id 
and b.periodo_id = a.periodo_id
and b.anno = anno_esercizio_prec;

-- annoImpImpegni_int := anno_esercizio::integer; 
annoImpImpegni_int := p_anno::integer; 

return query
select 
zz.*
from (
select 
tab1.*
from (
with struttura as (
select *
from fnc_bilr_struttura_cap_bilancio_spese (p_ente_prop_id,anno_esercizio,null) -- Potrebbe essere anche anno_esercizio_prec
),
capitoli_anno_prec as (
select 	programma.classif_id programma_id,
		macroaggr.classif_id macroaggregato_id,
       	capitolo.elem_code, capitolo.elem_desc, capitolo.elem_code2,
        capitolo.elem_desc2, capitolo.elem_code3, capitolo.elem_id
from siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     siac_r_bil_elem_stato r_capitolo_stato,
     siac_d_bil_elem_stato stato_capitolo,      
     siac_r_bil_elem_class r_capitolo_programma,
     siac_r_bil_elem_class r_capitolo_macroaggr, 	 
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo,
     siac_d_class_tipo programma_tipo,
     siac_t_class programma,
     siac_d_class_tipo macroaggr_tipo,
     siac_t_class macroaggr
where capitolo.elem_tipo_id = tipo_elemento.elem_tipo_id 						
and capitolo.elem_id = r_capitolo_stato.elem_id							
and	r_capitolo_stato.elem_stato_id = stato_capitolo.elem_stato_id		
and	capitolo.elem_id = r_capitolo_programma.elem_id							
and capitolo.elem_id = r_capitolo_macroaggr.elem_id							
and programma.classif_tipo_id = programma_tipo.classif_tipo_id 				
and programma.classif_id = r_capitolo_programma.classif_id					
and macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id 			
and macroaggr.classif_id = r_capitolo_macroaggr.classif_id					
and	capitolo.elem_id = r_cat_capitolo.elem_id				
and r_cat_capitolo.elem_cat_id = cat_del_capitolo.elem_cat_id		
and capitolo.ente_proprietario_id = p_ente_prop_id							
and capitolo.bil_id = bilancio_id_prec													
and programma_tipo.classif_tipo_code = 'PROGRAMMA'							
and	macroaggr_tipo.classif_tipo_code = 'MACROAGGREGATO'						
and	tipo_elemento.elem_tipo_code = 'CAP-UG'						     		
and stato_capitolo.elem_stato_code = 'VA' 
and cat_del_capitolo.elem_cat_code in ('FPV','FPVC')    
and	programma_tipo.data_cancellazione 			is null
and	programma.data_cancellazione 				is null
and	macroaggr_tipo.data_cancellazione 			is null
and	macroaggr.data_cancellazione 				is null
and	capitolo.data_cancellazione 				is null
and	tipo_elemento.data_cancellazione 			is null
and	r_capitolo_programma.data_cancellazione 	is null
and	r_capitolo_macroaggr.data_cancellazione 	is null 
and	stato_capitolo.data_cancellazione 			is null 
and	r_capitolo_stato.data_cancellazione 		is null
and	cat_del_capitolo.data_cancellazione 		is null
and	r_cat_capitolo.data_cancellazione           is null
),
capitoli_importo as ( -- Fondo pluriennale vincolato al 31 dicembre dell''esercizio N-1
select 		capitolo_importi.elem_id,
           	sum(capitolo_importi.elem_det_importo) importi_capitoli
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,
            siac_t_bil_elem 			capitolo,
            siac_d_bil_elem_tipo 		tipo_elemento,
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo
where capitolo_importi.ente_proprietario_id = p_ente_prop_id  								 
and	capitolo.elem_id = capitolo_importi.elem_id 
and	capitolo.elem_tipo_id = tipo_elemento.elem_tipo_id
and	capitolo_importi.elem_det_tipo_id = capitolo_imp_tipo.elem_det_tipo_id 		
and	capitolo_imp_periodo.periodo_id = capitolo_importi.periodo_id 
and	capitolo.elem_id = r_capitolo_stato.elem_id			
and	r_capitolo_stato.elem_stato_id = stato_capitolo.elem_stato_id
and	capitolo.elem_id = r_cat_capitolo.elem_id				
and	r_cat_capitolo.elem_cat_id = cat_del_capitolo.elem_cat_id	
and	capitolo.bil_id = bilancio_id_prec							
and	tipo_elemento.elem_tipo_code = 'CAP-UG'			  
and	capitolo_imp_periodo.anno = anno_esercizio_prec	
and	stato_capitolo.elem_stato_code = 'VA'								
and	cat_del_capitolo.elem_cat_code in ('FPV','FPVC')
and capitolo_imp_tipo.elem_det_tipo_code = 'STA'				
and	capitolo_importi.data_cancellazione 		is null
and	capitolo_imp_tipo.data_cancellazione 		is null
and	capitolo_imp_periodo.data_cancellazione 	is null
and	capitolo.data_cancellazione 				is null
and	tipo_elemento.data_cancellazione 			is null
and	stato_capitolo.data_cancellazione 			is null 
and	r_capitolo_stato.data_cancellazione 		is null
and cat_del_capitolo.data_cancellazione 		is null
and	r_cat_capitolo.data_cancellazione 			is null
group by capitolo_importi.elem_id
)
select 
struttura.missione_code::varchar,
struttura.missione_desc::varchar,
struttura.programma_code::varchar,
struttura.programma_desc::varchar,
capitoli_importo.importi_capitoli::numeric,
null::numeric spese_impegnate,
null::numeric spese_impegnate_anno1,
null::numeric spese_impegnate_anno2,
null::numeric spese_impegnate_anno_succ,
null::numeric importo_avanzo,
null::numeric importo_avanzo_anno1,
null::numeric importo_avanzo_anno2,
null::numeric importo_avanzo_anno_succ,
capitoli_anno_prec.elem_id::integer,
anno_esercizio::varchar
from struttura
left join capitoli_anno_prec on struttura.programma_id = capitoli_anno_prec.programma_id
                   and struttura.macroag_id = capitoli_anno_prec.macroaggregato_id
left join capitoli_importo on capitoli_anno_prec.elem_id = capitoli_importo.elem_id
) tab1
union all
select 
tab2.*
from (
with struttura as (
select *
from fnc_bilr_struttura_cap_bilancio_spese (p_ente_prop_id,anno_esercizio,null)
),
capitoli as (
select 	programma.classif_id programma_id,
		macroaggr.classif_id macroaggregato_id,
       	capitolo.elem_code, capitolo.elem_desc, capitolo.elem_code2,
        capitolo.elem_desc2, capitolo.elem_code3, capitolo.elem_id
from siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     siac_r_bil_elem_stato r_capitolo_stato,
     siac_d_bil_elem_stato stato_capitolo,      
     siac_r_bil_elem_class r_capitolo_programma,
     siac_r_bil_elem_class r_capitolo_macroaggr, 	 
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo,
     siac_d_class_tipo programma_tipo,
     siac_t_class programma,
     siac_d_class_tipo macroaggr_tipo,
     siac_t_class macroaggr
where capitolo.elem_tipo_id = tipo_elemento.elem_tipo_id 						
and capitolo.elem_id = r_capitolo_stato.elem_id							
and	r_capitolo_stato.elem_stato_id = stato_capitolo.elem_stato_id		
and	capitolo.elem_id = r_capitolo_programma.elem_id							
and capitolo.elem_id = r_capitolo_macroaggr.elem_id							
and programma.classif_tipo_id = programma_tipo.classif_tipo_id 				
and programma.classif_id = r_capitolo_programma.classif_id					
and macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id 				
and macroaggr.classif_id = r_capitolo_macroaggr.classif_id					
and	capitolo.elem_id = r_cat_capitolo.elem_id				
and r_cat_capitolo.elem_cat_id = cat_del_capitolo.elem_cat_id		
and capitolo.ente_proprietario_id = p_ente_prop_id							
and capitolo.bil_id = bilancio_id													
and programma_tipo.classif_tipo_code = 'PROGRAMMA'							
and	macroaggr_tipo.classif_tipo_code = 'MACROAGGREGATO'						
and	tipo_elemento.elem_tipo_code = 'CAP-UG'						     		
and stato_capitolo.elem_stato_code = 'VA' 
-- and cat_del_capitolo.elem_cat_code in ('FPV','FPVC')    
and	programma_tipo.data_cancellazione 			is null
and	programma.data_cancellazione 				is null
and	macroaggr_tipo.data_cancellazione 			is null
and	macroaggr.data_cancellazione 				is null
and	capitolo.data_cancellazione 				is null
and	tipo_elemento.data_cancellazione 			is null
and	r_capitolo_programma.data_cancellazione 	is null
and	r_capitolo_macroaggr.data_cancellazione 	is null 
and	stato_capitolo.data_cancellazione 			is null 
and	r_capitolo_stato.data_cancellazione 		is null
and	cat_del_capitolo.data_cancellazione 		is null
and	r_cat_capitolo.data_cancellazione           is null
),
dati_impegni as (
with importo_impegni as (
with   impegni as (
select ts_impegni_legati.movgest_ts_b_id,
       movimento.movgest_anno anno_impegno
from   siac_r_movgest_ts ts_impegni_legati
inner  join siac_t_movgest_ts ts_movimento on ts_impegni_legati.movgest_ts_b_id = ts_movimento.movgest_ts_id
inner  join siac_t_movgest movimento on ts_movimento.movgest_id = movimento.movgest_id
inner  join siac_r_movgest_ts_stato ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner  join siac_d_movgest_stato stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where  ts_impegni_legati.ente_proprietario_id = p_ente_prop_id
and    movimento.movgest_anno  >= annoImpImpegni_int
and    movimento.bil_id = bilancio_id
and    stato.movgest_stato_code in ('D','N')-- SIAC-5778
and    ts_impegni_legati.data_cancellazione is null
and    ts_movimento.data_cancellazione is null
and    movimento.data_cancellazione is null
and    ts_impegni_legati.validita_fine is null
and    ts_stato.data_cancellazione is null-- SIAC-5778
and    stato.data_cancellazione is null-- SIAC-5778 
group by ts_impegni_legati.movgest_ts_b_id, movimento.movgest_anno
),
imp_impegni_accertamenti as (
select ts_impegni_legati.movgest_ts_b_id,
       movimento.movgest_anno anno_accertamento,
       sum(ts_impegni_legati.movgest_ts_importo) movgest_ts_importo       
from   siac_r_movgest_ts ts_impegni_legati
inner  join siac_t_movgest_ts ts_movimento on ts_impegni_legati.movgest_ts_a_id = ts_movimento.movgest_ts_id
inner  join siac_t_movgest movimento on ts_movimento.movgest_id = movimento.movgest_id
inner  join siac_r_movgest_ts_stato ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner  join siac_d_movgest_stato stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where  ts_impegni_legati.ente_proprietario_id = p_ente_prop_id
and    ts_impegni_legati.avav_id is null
and    movimento.bil_id = bilancio_id
and    movimento.movgest_anno <= annoImpImpegni_int+2
and    stato.movgest_stato_code in ('D','N')-- SIAC-5778
and    ts_impegni_legati.data_cancellazione is null
and    ts_movimento.data_cancellazione is null
and    movimento.data_cancellazione is null
and    ts_impegni_legati.validita_fine is null
and    ts_stato.data_cancellazione is null-- SIAC-5778
and    stato.data_cancellazione is null-- SIAC-5778 
group by ts_impegni_legati.movgest_ts_b_id, movimento.movgest_anno 
),
imp_impegni_avanzo as (
select ts_impegni_legati.movgest_ts_b_id,
       sum(ts_impegni_legati.movgest_ts_importo) movgest_ts_importo,
       movimento.movgest_anno        
from   siac_r_movgest_ts ts_impegni_legati
inner  join siac_t_avanzovincolo avanzovincolo on ts_impegni_legati.avav_id = avanzovincolo.avav_id
inner  join siac_d_avanzovincolo_tipo tipo_avanzovincolo on avanzovincolo.avav_tipo_id = tipo_avanzovincolo.avav_tipo_id
inner  join siac_t_movgest_ts ts_movimento on ts_impegni_legati.movgest_ts_b_id = ts_movimento.movgest_ts_id
inner  join siac_t_movgest movimento on ts_movimento.movgest_id = movimento.movgest_id
inner  join siac_r_movgest_ts_stato ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner  join siac_d_movgest_stato stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where  ts_impegni_legati.ente_proprietario_id = p_ente_prop_id
and    movimento.bil_id = bilancio_id
and    ts_impegni_legati.movgest_ts_a_id is null
and    tipo_avanzovincolo.avav_tipo_code in ('AAM','FPVSC','FPVCC')
and    movimento.movgest_anno >= annoImpImpegni_int
and    stato.movgest_stato_code in ('D','N')-- SIAC-5778
and    ts_impegni_legati.data_cancellazione is null
and    avanzovincolo.data_cancellazione is null 
and    tipo_avanzovincolo.data_cancellazione is null
and    ts_movimento.data_cancellazione is null 
and    movimento.data_cancellazione is null
and    ts_impegni_legati.validita_fine is null
and    ts_stato.data_cancellazione is null-- SIAC-5778
and    stato.data_cancellazione is null-- SIAC-5778 
group by ts_impegni_legati.movgest_ts_b_id, movimento.movgest_anno 
)
select impegni.movgest_ts_b_id,
       case 
        when impegni.anno_impegno = annoImpImpegni_int and imp_impegni_accertamenti.anno_accertamento <= annoImpImpegni_int-1 then
             sum(imp_impegni_accertamenti.movgest_ts_importo)
       end spese_impegnate,  
       case 
        when impegni.anno_impegno = annoImpImpegni_int+1 and imp_impegni_accertamenti.anno_accertamento <= annoImpImpegni_int then
             sum(imp_impegni_accertamenti.movgest_ts_importo)
       end spese_impegnate_anno1,   
       case 
        when impegni.anno_impegno = annoImpImpegni_int+2 and imp_impegni_accertamenti.anno_accertamento <= annoImpImpegni_int+1 then
             sum(imp_impegni_accertamenti.movgest_ts_importo)
       end spese_impegnate_anno2,    
       case 
        when impegni.anno_impegno > annoImpImpegni_int+2 and imp_impegni_accertamenti.anno_accertamento <= annoImpImpegni_int+2 then
             sum(imp_impegni_accertamenti.movgest_ts_importo)
       end spese_impegnate_anno_succ,
       case 
        when impegni.anno_impegno = annoImpImpegni_int then
             sum(imp_impegni_avanzo.movgest_ts_importo)
       end importo_avanzo,    
       case 
        when impegni.anno_impegno = annoImpImpegni_int+1 then
             sum(imp_impegni_avanzo.movgest_ts_importo)
       end importo_avanzo_anno1,      
       case 
        when impegni.anno_impegno = annoImpImpegni_int+2 then
             sum(imp_impegni_avanzo.movgest_ts_importo)            
       end importo_avanzo_anno2,
       case 
        when impegni.anno_impegno > annoImpImpegni_int+2 then
             sum(imp_impegni_avanzo.movgest_ts_importo)            
       end importo_avanzo_anno_succ                      
from   impegni
left   join imp_impegni_accertamenti on impegni.movgest_ts_b_id = imp_impegni_accertamenti.movgest_ts_b_id
left   join imp_impegni_avanzo on impegni.movgest_ts_b_id = imp_impegni_avanzo.movgest_ts_b_id
group by impegni.movgest_ts_b_id, impegni.anno_impegno, imp_impegni_accertamenti.anno_accertamento
),
capitoli_impegni as (
select capitolo.elem_id, ts_movimento.movgest_ts_id
from  siac_t_bil_elem                 capitolo
inner join siac_r_movgest_bil_elem    r_mov_capitolo on r_mov_capitolo.elem_id = capitolo.elem_id
inner join siac_d_bil_elem_tipo       t_capitolo on capitolo.elem_tipo_id = t_capitolo.elem_tipo_id
inner join siac_t_movgest             movimento on r_mov_capitolo.movgest_id = movimento.movgest_id
inner join siac_t_movgest_ts          ts_movimento on movimento.movgest_id = ts_movimento.movgest_id
inner join siac_r_movgest_ts_stato    ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner join siac_d_movgest_stato       stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where capitolo.ente_proprietario_id = p_ente_prop_id
and   capitolo.bil_id =	bilancio_id
and   movimento.bil_id = bilancio_id
and   t_capitolo.elem_tipo_code = 'CAP-UG'
and   movimento.movgest_anno >= annoImpImpegni_int
and   stato.movgest_stato_code in ('D','N')-- SIAC-5778
and   capitolo.data_cancellazione is null 
and   r_mov_capitolo.data_cancellazione is null 
and   t_capitolo.data_cancellazione is null
and   movimento.data_cancellazione is null 
and   ts_movimento.data_cancellazione is null
and   ts_stato.data_cancellazione is null-- SIAC-5778
and   stato.data_cancellazione is null-- SIAC-5778 
)
select 
capitoli_impegni.elem_id,
sum(importo_impegni.spese_impegnate) spese_impegnate,
sum(importo_impegni.spese_impegnate_anno1) spese_impegnate_anno1,
sum(importo_impegni.spese_impegnate_anno2) spese_impegnate_anno2,
sum(importo_impegni.spese_impegnate_anno_succ) spese_impegnate_anno_succ,
sum(importo_impegni.importo_avanzo) importo_avanzo,
sum(importo_impegni.importo_avanzo_anno1) importo_avanzo_anno1,
sum(importo_impegni.importo_avanzo_anno2) importo_avanzo_anno2,
sum(importo_impegni.importo_avanzo_anno_succ) importo_avanzo_anno_succ
from capitoli_impegni
left join importo_impegni on capitoli_impegni.movgest_ts_id = importo_impegni.movgest_ts_b_id
group by capitoli_impegni.elem_id
)
select 
struttura.missione_code::varchar,
struttura.missione_desc::varchar,
struttura.programma_code::varchar,
struttura.programma_desc::varchar,
null::numeric importi_capitoli,
dati_impegni.spese_impegnate::numeric,
dati_impegni.spese_impegnate_anno1::numeric,
dati_impegni.spese_impegnate_anno2::numeric,
dati_impegni.spese_impegnate_anno_succ::numeric,
dati_impegni.importo_avanzo::numeric,
dati_impegni.importo_avanzo_anno1::numeric,
dati_impegni.importo_avanzo_anno2::numeric,
dati_impegni.importo_avanzo_anno_succ::numeric,
capitoli.elem_id::integer,
anno_esercizio::varchar
from struttura
left join capitoli on  struttura.programma_id = capitoli.programma_id
                   and struttura.macroag_id = capitoli.macroaggregato_id
left join dati_impegni on  capitoli.elem_id = dati_impegni.elem_id
) tab2
) as zz;

-- raise notice 'Dati % - %',anno_esercizio::varchar,anno_esercizio_prec::varchar;
-- raise notice 'Dati % - %',bilancio_id::varchar,bilancio_id_prec::varchar;

exception
when no_data_found THEN
raise notice 'nessun dato trovato per struttura bilancio';
return;
when others  THEN
RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;
-- SIAC-5778 FINE
-- SIAC-5852 Daniela 07.02.2018

CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_apertura_vincoli_popola(
  enteProprietarioId     integer,
  annoBilancio           integer,
  loginOperazione        varchar,
  dataElaborazione       timestamp,
  out faseBilElabRetId   integer,
  out codiceRisultato    integer,
  out messaggioRisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;

    movGestRec record;
    faseBilElabId     integer:=null;

    bilancioId        integer:=null;
  	bilancioPrecId    integer:=null;
    periodoId         integer:=null;
    periodoPrecId     integer:=null;
	dataInizioVal     timestamp:=null;

	faseOp            varchar(10):=null;

	movgestStatoAId   integer:=null;
	movGestTsDetTipoAId   integer:=null;

	movGestTipoIId        integer:=null;
    movGestTipoAId        integer:=null;
	movGestTsAId          integer:=null;

    -- tipo periodo annuale
    SY_PER_TIPO       CONSTANT varchar:='SY';
    -- tipo anno ordinario annuale
	BIL_ORD_TIPO      CONSTANT varchar:='BIL_ORD';


    APE_GEST_VINCOLI    CONSTANT varchar:='APE_GEST_VINCOLI';

	A_IMP_STATO       CONSTANT varchar:='A';
	IMPOATT_TIPO    CONSTANT varchar:='A';

    I_MOVGEST_TIPO  CONSTANT varchar:='I';
    A_MOVGEST_TIPO  CONSTANT varchar:='A';
    E_FASE CONSTANT varchar:='E';
    G_FASE CONSTANT varchar:='G';
BEGIN
	faseBilElabRetId:=null;
    codiceRisultato:=null;
    messaggioRisultato:=null;

    dataInizioVal:= clock_timestamp();

	strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento vincoli da Gestione precedente. Anno bilancio='||annoBilancio::varchar||'. POPOLA.';

    strMessaggio:='Verifica esistenza fase elaborazione '||APE_GEST_VINCOLI||' IN CORSO.';
    select 1 into codResult
    from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.fase_bil_elab_tipo_code=APE_GEST_VINCOLI
    and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
    and   fase.fase_bil_elab_esito like 'IN%'
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;
    if codResult is not null then
    	raise exception ' Esistenza fase in corso.';
    end if;

    -- inserimento fase_bil_t_elaborazione
	strMessaggio:='Inserimento fase elaborazione [fase_bil_t_elaborazione].';
    insert into fase_bil_t_elaborazione
    (fase_bil_elab_esito, fase_bil_elab_esito_msg,
     fase_bil_elab_tipo_id,
     ente_proprietario_id,validita_inizio, login_operazione)
    (select 'IN','ELABORAZIONE FASE BILANCIO '||APE_GEST_VINCOLI||' IN CORSO.',
            tipo.fase_bil_elab_tipo_id,enteProprietarioId, dataInizioVal, loginOperazione
     from fase_bil_d_elaborazione_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.fase_bil_elab_tipo_code=APE_GEST_VINCOLI
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null)
     returning fase_bil_elab_id into faseBilElabId;

     if faseBilElabId is null then
     	raise exception ' Inserimento non effettuato.';
     end if;


    strMessaggio:='Inserimento LOG.';
	codResult:=null;
	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;


	 strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
     select bil.bil_id , per.periodo_id into strict bilancioId, periodoId
     from siac_t_bil bil, siac_t_periodo per
     where bil.ente_proprietario_id=enteProprietarioId
     and   per.periodo_id=bil.periodo_id
     and   per.anno::INTEGER=annoBilancio
     and   bil.data_cancellazione is null
     and   per.data_cancellazione is null;


	 strMessaggio:='Verifica fase di bilancio di corrente.';
	 select fase.fase_operativa_code into faseOp
     from siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where r.bil_id=bilancioId
     and   fase.fase_operativa_id=r.fase_operativa_id
     and   r.data_cancellazione is null
     and   r.validita_fine is null;
     if faseOp is null or faseOp not in (E_FASE,G_FASE) then
     	raise exception ' Il bilancio deve essere in fase % o %.',E_FASE,G_FASE;
     end if;

     strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio-1='||(annoBilancio-1)::varchar||'.';
     select bil.bil_id , per.periodo_id into strict bilancioPrecId, periodoPrecId
     from siac_t_bil bil, siac_t_periodo per
     where bil.ente_proprietario_id=enteProprietarioId
     and   per.periodo_id=bil.periodo_id
     and   per.anno::INTEGER=annoBilancio-1
     and   bil.data_cancellazione is null
     and   per.data_cancellazione is null;




     strMessaggio:='Lettura id identificativo per movgestStatoAId='||A_IMP_STATO||'.';
     select stato.movgest_stato_id into strict movgestStatoAId
     from siac_d_movgest_stato stato
     where stato.ente_proprietario_id=enteProprietarioId
     and   stato.movgest_stato_code=A_IMP_STATO
     and   stato.data_cancellazione is null
     and   stato.validita_fine is null;


     strMessaggio:='Lettura id identificativo per movGestTipoIId='||I_MOVGEST_TIPO||'.';
     select tipo.movgest_tipo_id into strict movGestTipoIId
     from siac_d_movgest_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_tipo_code=I_MOVGEST_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

     strMessaggio:='Lettura id identificativo per movGestTipoAId='||A_MOVGEST_TIPO||'.';
     select tipo.movgest_tipo_id into strict movGestTipoAId
     from siac_d_movgest_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_tipo_code=A_MOVGEST_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

     -- 07.02.2018 Daniela SIAC-5852

     strMessaggio:='Apertura avanzo vincolo per anno annoBilancio='||annoBilancio::varchar||'.INIZIO.';
     codResult:=null;
     insert into fase_bil_t_elaborazione_log
      (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
      )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
         raise exception ' Errore in inserimento LOG.';
     end if;

     insert into siac_t_avanzovincolo
     (avav_tipo_id, avav_importo_massimale,validita_inizio,ente_proprietario_id,login_operazione)
     select a.avav_tipo_id, 0, to_date('01/01/'||annoBilancio::varchar,'dd/MM/yyyy'),enteProprietarioId, loginOperazione
     from siac_t_avanzovincolo a
     where a.ente_proprietario_id = enteProprietarioId
     and   a.validita_inizio = to_date ('01/01/'||(annoBilancio-1)::varchar,'dd/MM/yyyy')
     and   a.validita_fine is NULL
     and   a.data_cancellazione is NULL
     and   not exists (select 1 from siac_t_avanzovincolo b
		  			   where b.ente_proprietario_id=a.ente_proprietario_id
					   and b.validita_inizio = to_date('01/01/'||annoBilancio::varchar,'dd/MM/yyyy')
  					   and b.avav_tipo_id = a.avav_tipo_id
                       and b.validita_fine is null
                       and b.data_cancellazione is null);

     strMessaggio:='Apertura avanzo vincolo per anno bilancio annoBilancio='||annoBilancio::varchar||'.FINE.';
     codResult:=null;
     insert into fase_bil_t_elaborazione_log
      (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
      )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
         raise exception ' Errore in inserimento LOG.';
     end if;

     strMessaggio:='Chiusura avanzo vincolo per anno annoBilancio-1='||(annoBilancio-1)::varchar||'.INIZIO.';
     codResult:=null;
     insert into fase_bil_t_elaborazione_log
      (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
      )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
         raise exception ' Errore in inserimento LOG.';
     end if;

     Update siac_t_avanzovincolo
      set validita_fine = to_date('31/12/'||(annoBilancio-1)::varchar,'dd/MM/yyyy')
      , login_operazione = login_operazione||'-'||loginOperazione
      , data_modifica = now()
     where ente_proprietario_id = enteProprietarioId
     and   validita_fine is null
     and   data_cancellazione is null
     and   validita_inizio = to_date('01/01/'||(annoBilancio-1)::varchar,'dd/MM/yyyy');

     strMessaggio:='Chiusura avanzo vincolo per anno annoBilancio-1='||(annoBilancio-1)::varchar||'.FINE.';
     codResult:=null;
     insert into fase_bil_t_elaborazione_log
      (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
      )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
         raise exception ' Errore in inserimento LOG.';
     end if;

    strMessaggio:='Verifica esistenza vincoli su movimenti da ribaltare INIZIO.';
    codResult:=null;
	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
    end if;

    -- 06.12.2017 Sofia siac-5276 - revisione ribaltamento vincoli tra impegni-accertamenti
    codResult:=null;
	select 1 into codResult
    from siac_r_movgest_ts r,
         siac_t_movgest mb,siac_t_movgest_ts tsb
    where mb.ente_proprietario_id=enteProprietarioId
    and   mb.movgest_tipo_id=movGestTipoIId
    and   mb.bil_id=bilancioPrecId
    and   mb.movgest_anno::INTEGER>=annoBilancio
    and   tsb.movgest_id=mb.movgest_id
    and   r.movgest_ts_b_id=tsb.movgest_ts_id
    and   mb.data_cancellazione is null
    and   mb.validita_fine is null
    and   tsb.data_cancellazione is null
    and   tsb.validita_fine is null
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    and   exists (select 1 from siac_t_movgest mnew, siac_t_movgest_ts tsnew, siac_r_movgest_ts_stato rs
   				  where mnew.bil_id=bilancioId
                  and   mnew.movgest_tipo_id=mb.movgest_tipo_id
                  and   mnew.movgest_anno=mb.movgest_anno
                  and   mnew.movgest_numero=mb.movgest_numero
                  and   tsnew.movgest_id=mnew.movgest_id
                  and   tsnew.movgest_ts_tipo_id=tsb.movgest_ts_tipo_id
                  and   tsnew.movgest_ts_code=tsb.movgest_ts_code
                  and   rs.movgest_ts_id=tsnew.movgest_ts_id
                  and   rs.movgest_stato_id!=movgestStatoAId
                  and   rs.data_cancellazione is null
                  and   rs.validita_fine is null
                  and   mnew.data_cancellazione is null
                  and   mnew.validita_fine is null
                  and   tsnew.data_cancellazione is null
                  and   tsnew.validita_fine is null);

	 if codResult is null then
     	raise exception ' Nessun vincolo da ribaltare.';
     end if;

     strMessaggio:='Verifica esistenza vincoli su movimenti da ribaltare FINE.';
     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;


     strMessaggio:='Inserimento fase_bil_t_gest_apertura_vincoli - INIZIO inserimenti';
     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

     strMessaggio:='Inserimento fase_bil_t_gest_apertura_vincoli - INIZIO inserimenti - caso 1';
     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

     -- caso 1
	 -- il movimento nel bilancio precedente presentava un legame ad avanzo_tipo FPVCC conto capitale o FPVSC spesa corrente:
	 --  in questo caso ricreare un vincolo analogo nel
	 --  nuovo bilancio per la stessa quota senza legame ad accertamento ( solo movgest_ts_id_b )
     insert into fase_bil_t_gest_apertura_vincoli
     (fase_bil_elab_id,
      movgest_orig_ts_b_id,
      movgest_orig_ts_r_id,
      bil_orig_id,
      importo_orig_vinc,
      movgest_ts_b_id,
      importo_vinc,
	  avav_id,
      bil_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
      )
      (
      with
      vincPrec as
      (
      select mb.movgest_anno::integer, mb.movgest_numero::integer,
             tsb.movgest_ts_code::integer,
             tsb.movgest_ts_tipo_id,
             mb.movgest_id, tsb.movgest_ts_id,
             r.movgest_ts_r_id,
             r.avav_id, r.movgest_ts_importo
             ,tipo.avav_tipo_id
      from siac_r_movgest_ts r,
           siac_t_movgest mb,siac_t_movgest_ts tsb ,siac_t_avanzovincolo av,siac_d_avanzovincolo_tipo tipo
      where mb.bil_id=bilancioPrecId
      and   mb.movgest_tipo_id=movGestTipoIId
      and   mb.movgest_anno::INTEGER>=annoBilancio
	  and   tsb.movgest_id=mb.movgest_id
	  and   r.movgest_ts_b_id=tsb.movgest_ts_id
      and   r.movgest_ts_a_id is null
      and   av.avav_id=r.avav_id
      and   tipo.avav_tipo_id=av.avav_tipo_id
      and   tipo.avav_tipo_code in ('FPVCC','FPVSC')
	  and   mb.data_cancellazione is null
	  and   mb.validita_fine is null
	  and   tsb.data_cancellazione is null
	  and   tsb.validita_fine is null
	  and   r.data_cancellazione is null
      and   r.validita_fine is null
      ),
      impNew as
      (select mnew.movgest_anno::integer, mnew.movgest_numero::integer,
              tsnew.movgest_ts_code::integer,
              tsnew.movgest_ts_tipo_id,
              mnew.movgest_id, tsnew.movgest_ts_id
       from siac_t_movgest mnew, siac_t_movgest_ts tsnew, siac_r_movgest_ts_stato rs
       where mnew.bil_id=bilancioId
       and   mnew.movgest_tipo_id=movGestTipoIId
       and   mnew.movgest_anno::integer>=annoBilancio
       and   tsnew.movgest_id=mnew.movgest_id
       and   rs.movgest_ts_id=tsnew.movgest_ts_id
       and   rs.movgest_stato_id!=movgestStatoAId
       and   rs.data_cancellazione is null
       and   rs.validita_fine is null
       and   mnew.data_cancellazione is null
       and   mnew.validita_fine is null
       and   tsnew.data_cancellazione is null
       and   tsnew.validita_fine is null
      )
      -- 07.02.2018 - Daniela SIAC-5852
      , avavNew as
      ( select av.avav_id, av.avav_tipo_id
        from siac_t_avanzoVincolo av
        where av.ente_proprietario_id = enteProprietarioId
        and   av.validita_inizio = to_date('01/01/'||annoBilancio::varchar,'dd/MM/yyyy')
        and   av.validita_fine is null
        and   av.data_cancellazione is NULL
        )
      select faseBilElabId, 				-- fase_bil_elab_id
             vincPrec.movgest_ts_id, 		-- movgest_orig_ts_b_id
             vincPrec.movgest_ts_r_id,  	-- movgest_orig_ts_r_id
             bilancioPrecId, 				-- bil_orig_id
             vincPrec.movgest_ts_importo, 	-- importo_orig_vinc
             impNew.movgest_ts_id, 			-- movgest_ts_b_id
             vincPrec.movgest_ts_importo, 	-- importo_vinc
--             vincPrec.avav_id,  			-- avav_id
             avavNew.avav_id,				-- avav_id
             bilancioId, 					-- bil_id
       		 dataInizioVal,
	         loginOperazione,
	         enteProprietarioId
      from vincPrec, impNew, avavNew
      where vincPrec.movgest_anno=impNew.movgest_anno
      and   vincPrec.movgest_numero=impNew.movgest_numero
      and   vincPrec.movgest_ts_code=impNew.movgest_ts_code
      and   vincPrec.movgest_ts_tipo_id=impNew.movgest_ts_tipo_id
      and   avavNew.avav_tipo_id = vincPrec.avav_tipo_id
      );


     strMessaggio:='Inserimento fase_bil_t_gest_apertura_vincoli - FINE inserimenti - caso 1';
     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

     strMessaggio:='Inserimento fase_bil_t_gest_apertura_vincoli - INIZIO inserimenti - caso 2.a';
     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;
     -- caso 2.a
     -- il movimento nel bilancio precedente presentava un legame ad
     -- avanzo_tipo Avanzo di amministrazione
     -- creare un legame nuovo bilancio del tipo FPV  per la stessa quota
     -- (la tipologia conto capitale o spesa corrente da determinare sulla base del titolo di spesa)
     -- titolo 1 e 4 - FPVSC corrente
     -- titolo 2 e 3 - FPVCC in conto capitale
     insert into fase_bil_t_gest_apertura_vincoli
     (fase_bil_elab_id,
      movgest_orig_ts_b_id,
      movgest_orig_ts_r_id,
      bil_orig_id,
      importo_orig_vinc,
      movgest_ts_b_id,
      importo_vinc,
	  avav_id,
      bil_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
      )
      (
      with
      vincPrec as
      (
      select mb.movgest_anno::integer, mb.movgest_numero::integer,
             tsb.movgest_ts_code::integer,
             tsb.movgest_ts_tipo_id,
             mb.movgest_id, tsb.movgest_ts_id,
             r.movgest_ts_r_id,
             r.avav_id, r.movgest_ts_importo
      from siac_r_movgest_ts r,
           siac_t_movgest mb,siac_t_movgest_ts tsb ,siac_t_avanzovincolo av,siac_d_avanzovincolo_tipo tipo
      where mb.bil_id=bilancioPrecId
	  and   mb.movgest_tipo_id=movGestTipoIId
      and   mb.movgest_anno::INTEGER>=annoBilancio
	  and   tsb.movgest_id=mb.movgest_id
	  and   r.movgest_ts_b_id=tsb.movgest_ts_id
      and   r.movgest_ts_a_id is null
      and   av.avav_id=r.avav_id
      and   tipo.avav_tipo_id=av.avav_tipo_id
      and   tipo.avav_tipo_code='AAM'
	  and   mb.data_cancellazione is null
	  and   mb.validita_fine is null
	  and   tsb.data_cancellazione is null
	  and   tsb.validita_fine is null
	  and   r.data_cancellazione is null
      and   r.validita_fine is null
      ),
      impNew as
      (select mnew.movgest_anno::integer, mnew.movgest_numero::integer,
              tsnew.movgest_ts_code::integer,
              tsnew.movgest_ts_tipo_id,
              mnew.movgest_id, tsnew.movgest_ts_id
       from siac_t_movgest mnew, siac_t_movgest_ts tsnew, siac_r_movgest_ts_stato rs
       where mnew.bil_id=bilancioId
       and   mnew.movgest_tipo_id=movGestTipoIId
       and   mnew.movgest_anno::integer>=annoBilancio
       and   tsnew.movgest_id=mnew.movgest_id
       and   rs.movgest_ts_id=tsnew.movgest_ts_id
       and   rs.movgest_stato_id!=movgestStatoAId
       and   rs.data_cancellazione is null
       and   rs.validita_fine is null
       and   mnew.data_cancellazione is null
       and   mnew.validita_fine is null
       and   tsnew.data_cancellazione is null
       and   tsnew.validita_fine is null
      ),
      titoloNew as
      (
      	select rmov.movgest_id, cTitolo.classif_code::integer titolo_uscita,
               ( case when cTitolo.classif_code::integer in (1,4)  -- titolo 1 e 4 - FPVSC corrente
                      then 'FPVSC'
                      when cTitolo.classif_code::integer in (2,3)  -- titolo 2 e 3 - FPVCC in conto capitale
                      then 'FPVCC'
                      else null end ) tipo_avanzo
        from siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,
             siac_r_bil_elem_class rc,siac_t_class cMacro, siac_d_class_tipo tipoMacro,
             siac_r_class_fam_tree rfam,
             siac_t_class cTitolo, siac_d_class_tipo tipoTitolo,
             siac_r_movgest_bil_elem rmov
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.elem_tipo_code='CAP-UG'
        and   e.elem_tipo_id=tipo.elem_tipo_id
        and   e.bil_id=bilancioId
        and   rc.elem_id=e.elem_id
        and   cMacro.classif_id=rc.classif_id
        and   tipoMacro.classif_tipo_id=cMacro.classif_tipo_id
        and   tipomacro.classif_tipo_code='MACROAGGREGATO'
        and   rfam.classif_id=cMacro.classif_id
        and   cTitolo.classif_id=rfam.classif_id_padre
        and   tipoTitolo.classif_tipo_id=cTitolo.classif_tipo_id
        and   tipoTitolo.classif_tipo_code='TITOLO_SPESA'
        and   rmov.elem_id=e.elem_id
        and   e.data_cancellazione is null
        and   e.validita_fine is null
        and   rc.data_cancellazione is null
        and   rc.validita_fine is null
        and   rfam.data_cancellazione is null
        and   rfam.validita_fine is null
        and   rmov.data_cancellazione is null
        and   rmov.validita_fine is null
      ),
      tipoAv as
      (
       select av.avav_id, tipoav.avav_tipo_code
       from siac_t_avanzovincolo av, siac_d_avanzovincolo_tipo tipoav
       where tipoav.ente_proprietario_id=enteProprietarioId
       and   av.avav_tipo_id=tipoav.avav_tipo_id
       and   tipoav.avav_tipo_code in ('FPVSC','FPVCC')
       -- 07.02.2018 - Daniela SIAC-5852
       and   av.validita_inizio = to_date('01/01/'||annoBilancio::varchar,'dd/MM/yyyy')
       and   av.validita_fine is null
       and   av.data_cancellazione is NULL
      )
      select faseBilElabId, 				-- fase_bil_elab_id
             vincPrec.movgest_ts_id, 		-- movgest_orig_ts_b_id
             vincPrec.movgest_ts_r_id,  	-- movgest_orig_ts_r_id
             bilancioPrecId, 				-- bil_orig_id
             vincPrec.movgest_ts_importo, 	-- importo_orig_vinc
             impNew.movgest_ts_id, 			-- movgest_ts_b_id
             vincPrec.movgest_ts_importo, 	-- importo_vinc
             tipoAv.avav_id,  				-- avav_id
             bilancioId, 					-- bil_id
       		 dataInizioVal,
	         loginOperazione,
	         enteProprietarioId
      from vincPrec, impNew, titoloNew, tipoAv
      where vincPrec.movgest_anno=impNew.movgest_anno
      and   vincPrec.movgest_numero=impNew.movgest_numero
      and   vincPrec.movgest_ts_code=impNew.movgest_ts_code
      and   vincPrec.movgest_ts_tipo_id=impNew.movgest_ts_tipo_id
      and   titoloNew.movgest_id=impNew.movgest_id
      and   tipoAv.avav_tipo_code=titoloNew.tipo_avanzo
      );

     strMessaggio:='Inserimento fase_bil_t_gest_apertura_vincoli - FINE inserimenti - caso 2.a';
     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

	 strMessaggio:='Inserimento fase_bil_t_gest_apertura_vincoli - INIZIO inserimenti - caso 2.b';
     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;
     -- caso 2.b
     -- il movimento nel bilancio precedente presentava un legame ad
     -- un accertamento con anno < del nuovo bilancio:
     -- creare un legame nuovo bilancio del tipo FPV  per la stessa quota
     -- (la tipologia conto capitale o spesa corrente da determinare sulla base del titolo di spesa)
     -- titolo 1 e 4 - FPVSC corrente
     -- titolo 2 e 3 - FPVCC in conto capitale
     insert into fase_bil_t_gest_apertura_vincoli
     (fase_bil_elab_id,
      movgest_orig_ts_b_id,
      movgest_orig_ts_a_id,
      movgest_orig_ts_r_id,
      bil_orig_id,
      importo_orig_vinc,
      movgest_ts_b_id,
      importo_vinc,
	  avav_id,
      bil_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
      )
      (
      with
      vincPrec as
      (
      select mb.movgest_anno::integer, mb.movgest_numero::integer,
             tsb.movgest_ts_code::integer,
             tsb.movgest_ts_tipo_id,
             mb.movgest_id, tsb.movgest_ts_id,
             ma.movgest_id movgest_a_id, tsa.movgest_ts_id movgest_ts_a_id,
             r.movgest_ts_r_id,
             r.movgest_ts_importo
      from siac_r_movgest_ts r,
           siac_t_movgest mb,siac_t_movgest_ts tsb ,
           siac_t_movgest ma,siac_t_movgest_ts tsa
      where mb.bil_id=bilancioPrecId
	  and   mb.movgest_tipo_id=movGestTipoIId
      and   mb.movgest_anno::INTEGER>=annoBilancio
	  and   tsb.movgest_id=mb.movgest_id
	  and   r.movgest_ts_b_id=tsb.movgest_ts_id
      and   tsa.movgest_ts_id=r.movgest_ts_a_id
      and   ma.movgest_id=tsa.movgest_id
      and   ma.movgest_tipo_id=movGestTipoAId
      and   ma.bil_id=bilancioPrecId
      and   ma.movgest_anno::INTEGER<annoBilancio
	  and   mb.data_cancellazione is null
	  and   mb.validita_fine is null
	  and   tsb.data_cancellazione is null
	  and   tsb.validita_fine is null
	  and   ma.data_cancellazione is null
	  and   ma.validita_fine is null
	  and   tsa.data_cancellazione is null
	  and   tsa.validita_fine is null
	  and   r.data_cancellazione is null
      and   r.validita_fine is null
      ),
      impNew as
      (select mnew.movgest_anno::integer, mnew.movgest_numero::integer,
              tsnew.movgest_ts_code::integer,
              tsnew.movgest_ts_tipo_id,
              mnew.movgest_id, tsnew.movgest_ts_id
       from siac_t_movgest mnew, siac_t_movgest_ts tsnew, siac_r_movgest_ts_stato rs
       where mnew.bil_id=bilancioId
       and   mnew.movgest_tipo_id=movGestTipoIId
       and   mnew.movgest_anno::integer>=annoBilancio
       and   tsnew.movgest_id=mnew.movgest_id
       and   rs.movgest_ts_id=tsnew.movgest_ts_id
       and   rs.movgest_stato_id!=movgestStatoAId
       and   rs.data_cancellazione is null
       and   rs.validita_fine is null
       and   mnew.data_cancellazione is null
       and   mnew.validita_fine is null
       and   tsnew.data_cancellazione is null
       and   tsnew.validita_fine is null
      ),
      titoloNew as
      (
      	select rmov.movgest_id, cTitolo.classif_code::integer titolo_uscita,
               ( case when cTitolo.classif_code::integer in (1,4)  -- titolo 1 e 4 - FPVSC corrente
                      then 'FPVSC'
                      when cTitolo.classif_code::integer in (2,3)  -- titolo 2 e 3 - FPVCC in conto capitale
                      then 'FPVCC'
                      else null end ) tipo_avanzo
        from siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,
             siac_r_bil_elem_class rc,siac_t_class cMacro, siac_d_class_tipo tipoMacro,
             siac_r_class_fam_tree rfam,
             siac_t_class cTitolo, siac_d_class_tipo tipoTitolo,
             siac_r_movgest_bil_elem rmov
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.elem_tipo_code='CAP-UG'
        and   e.elem_tipo_id=tipo.elem_tipo_id
        and   e.bil_id=bilancioId
        and   rc.elem_id=e.elem_id
        and   cMacro.classif_id=rc.classif_id
        and   tipoMacro.classif_tipo_id=cMacro.classif_tipo_id
        and   tipomacro.classif_tipo_code='MACROAGGREGATO'
        and   rfam.classif_id=cMacro.classif_id
        and   cTitolo.classif_id=rfam.classif_id_padre
        and   tipoTitolo.classif_tipo_id=cTitolo.classif_tipo_id
        and   tipoTitolo.classif_tipo_code='TITOLO_SPESA'
        and   rmov.elem_id=e.elem_id
        and   e.data_cancellazione is null
        and   e.validita_fine is null
        and   rc.data_cancellazione is null
        and   rc.validita_fine is null
        and   rfam.data_cancellazione is null
        and   rfam.validita_fine is null
        and   rmov.data_cancellazione is null
        and   rmov.validita_fine is null
      ),
      tipoAv as
      (
       select av.avav_id, tipoav.avav_tipo_code
       from siac_t_avanzovincolo av, siac_d_avanzovincolo_tipo tipoav
       where tipoav.ente_proprietario_id=enteProprietarioId
       and   av.avav_tipo_id=tipoav.avav_tipo_id
       and   tipoav.avav_tipo_code in ('FPVSC','FPVCC')
       -- 07.02.2018 - Daniela SIAC-5852
       and   av.validita_inizio = to_date('01/01/'||annoBilancio::varchar,'dd/MM/yyyy')
       and   av.validita_fine is null
       and   av.data_cancellazione is NULL
      )
      select faseBilElabId, 				-- fase_bil_elab_id
             vincPrec.movgest_ts_id, 		-- movgest_orig_ts_b_id
             vincPrec.movgest_ts_a_id, 		-- movgest_orig_ts_a_id
             vincPrec.movgest_ts_r_id,  	-- movgest_orig_ts_r_id
             bilancioPrecId, 				-- bil_orig_id
             vincPrec.movgest_ts_importo, 	-- importo_orig_vinc
             impNew.movgest_ts_id, 			-- movgest_ts_b_id
             vincPrec.movgest_ts_importo, 	-- importo_vinc
             tipoAv.avav_id,  				-- avav_id
             bilancioId, 					-- bil_id
             dataInizioVal,
	         loginOperazione,
	         enteProprietarioId
      from vincPrec, impNew, titoloNew, tipoAv
      where vincPrec.movgest_anno=impNew.movgest_anno
      and   vincPrec.movgest_numero=impNew.movgest_numero
      and   vincPrec.movgest_ts_code=impNew.movgest_ts_code
      and   vincPrec.movgest_ts_tipo_id=impNew.movgest_ts_tipo_id
      and   titoloNew.movgest_id=impNew.movgest_id
      and   tipoAv.avav_tipo_code=titoloNew.tipo_avanzo
      );

     strMessaggio:='Inserimento fase_bil_t_gest_apertura_vincoli - FINE inserimenti - caso 2.b';
     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;


     strMessaggio:='Inserimento fase_bil_t_gest_apertura_vincoli - INIZIO inserimenti - caso 3';
     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

	--caso 3 : il movimento nel bilancio precedente presentava un legame ad un accertamento di competenza / pluriennale rispetto 
	 -- al nuovo bilancio: ricreare lo stesso vincolo per la quota cosi' come presente nel vecchio bilancio 
	 --( l'accertamento deve esistere nel nuovo bilancio ) movgest_ts_id_b e movgest_ts_id_a

	 insert into fase_bil_t_gest_apertura_vincoli
     (fase_bil_elab_id,
      movgest_orig_ts_b_id,
      movgest_orig_ts_a_id,
      movgest_orig_ts_r_id,
      bil_orig_id,
      importo_orig_vinc,
      movgest_ts_b_id,
      movgest_ts_a_id,
      importo_vinc,
	  avav_id,
      bil_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
      )
      (
      with
      vincPrec as
      (
      select mb.movgest_anno::integer, mb.movgest_numero::integer,
             tsb.movgest_ts_code::integer,
             tsb.movgest_ts_tipo_id,
             mb.movgest_id, tsb.movgest_ts_id,
             ma.movgest_anno::integer movgest_anno_a, ma.movgest_numero::integer movgest_numero_a,
             tsa.movgest_ts_code::integer movgest_ts_code_a,
             tsa.movgest_ts_tipo_id movgest_ts_tipo_a_id,
             ma.movgest_id movgest_a_id, tsa.movgest_ts_id movgest_ts_a_id,
             r.movgest_ts_r_id,
             r.movgest_ts_importo,
             r.avav_id,
             av.avav_tipo_id
      from siac_r_movgest_ts r left outer join siac_t_avanzovincolo av on (r.avav_id = av.avav_id)
      	   ,siac_t_movgest mb,siac_t_movgest_ts tsb ,
           siac_t_movgest ma,siac_t_movgest_ts tsa
      where mb.bil_id=bilancioPrecId
	  and   mb.movgest_tipo_id=movGestTipoIId
      and   mb.movgest_anno::INTEGER>=annoBilancio
	  and   tsb.movgest_id=mb.movgest_id
	  and   r.movgest_ts_b_id=tsb.movgest_ts_id
      and   tsa.movgest_ts_id=r.movgest_ts_a_id
      and   ma.movgest_id=tsa.movgest_id
      and   ma.movgest_tipo_id=movGestTipoAId
      and   ma.bil_id=bilancioPrecId
      and   ma.movgest_anno::INTEGER>=annoBilancio
	  and   mb.data_cancellazione is null
	  and   mb.validita_fine is null
	  and   tsb.data_cancellazione is null
	  and   tsb.validita_fine is null
	  and   ma.data_cancellazione is null
	  and   ma.validita_fine is null
	  and   tsa.data_cancellazione is null
	  and   tsa.validita_fine is null
	  and   r.data_cancellazione is null
      and   r.validita_fine is null
      ),
      impNew as
      (select mnew.movgest_anno::integer, mnew.movgest_numero::integer,
              tsnew.movgest_ts_code::integer,
              tsnew.movgest_ts_tipo_id,
              mnew.movgest_id, tsnew.movgest_ts_id
       from siac_t_movgest mnew, siac_t_movgest_ts tsnew, siac_r_movgest_ts_stato rs
       where mnew.bil_id=bilancioId
       and   mnew.movgest_tipo_id=movGestTipoIId
       and   mnew.movgest_anno::integer>=annoBilancio
       and   tsnew.movgest_id=mnew.movgest_id
       and   rs.movgest_ts_id=tsnew.movgest_ts_id
       and   rs.movgest_stato_id!=movgestStatoAId
       and   rs.data_cancellazione is null
       and   rs.validita_fine is null
       and   mnew.data_cancellazione is null
       and   mnew.validita_fine is null
       and   tsnew.data_cancellazione is null
       and   tsnew.validita_fine is null
      ),
      accNew as
      (select mnew.movgest_anno::integer, mnew.movgest_numero::integer,
              tsnew.movgest_ts_code::integer,
              tsnew.movgest_ts_tipo_id,
              mnew.movgest_id, tsnew.movgest_ts_id
       from siac_t_movgest mnew, siac_t_movgest_ts tsnew, siac_r_movgest_ts_stato rs
       where mnew.bil_id=bilancioId
       and   mnew.movgest_tipo_id=movGestTipoAId
       and   mnew.movgest_anno::integer>=annoBilancio
       and   tsnew.movgest_id=mnew.movgest_id
       and   rs.movgest_ts_id=tsnew.movgest_ts_id
       and   rs.movgest_stato_id!=movgestStatoAId
       and   rs.data_cancellazione is null
       and   rs.validita_fine is null
       and   mnew.data_cancellazione is null
       and   mnew.validita_fine is null
       and   tsnew.data_cancellazione is null
       and   tsnew.validita_fine is null
      )
      -- 07.02.2018 - Daniela SIAC-5852
      , avavNew as
      ( select av.avav_id, av.avav_tipo_id
        from siac_t_avanzoVincolo av
        where av.ente_proprietario_id = enteProprietarioId
        and   av.validita_inizio = to_date('01/01/'||annoBilancio::varchar,'dd/MM/yyyy')
        and   av.validita_fine is null
        and   av.data_cancellazione is NULL
        )
      select faseBilElabId, 				-- fase_bil_elab_id
             vincPrec.movgest_ts_id, 		-- movgest_orig_ts_b_id
             vincPrec.movgest_ts_a_id, 		-- movgest_orig_ts_a_id
             vincPrec.movgest_ts_r_id,  	-- movgest_orig_ts_r_id
             bilancioPrecId, 				-- bil_orig_id
             vincPrec.movgest_ts_importo, 	-- importo_orig_vinc
             impNew.movgest_ts_id, 			-- movgest_ts_b_id
             accNew.movgest_ts_id,          -- movgest_ts_a_id
             vincPrec.movgest_ts_importo, 	-- importo_vinc
--             vincPrec.avav_id,  			-- avav_id
             avavNew.avav_id,  				-- avav_id
             bilancioId, 					-- bil_id
       		 dataInizioVal,
	         loginOperazione,
	         enteProprietarioId
      from vincPrec left outer join avavNew on (avavNew.avav_tipo_id = vincPrec.avav_tipo_id)
      , impNew, accNew
      where vincPrec.movgest_anno=impNew.movgest_anno
      and   vincPrec.movgest_numero=impNew.movgest_numero
      and   vincPrec.movgest_ts_code=impNew.movgest_ts_code
      and   vincPrec.movgest_ts_tipo_id=impNew.movgest_ts_tipo_id
      and   vincPrec.movgest_anno_a=accNew.movgest_anno
      and   vincPrec.movgest_numero_a=accNew.movgest_numero
      and   vincPrec.movgest_ts_code_a=accNew.movgest_ts_code
      and   vincPrec.movgest_ts_tipo_a_id=accNew.movgest_ts_tipo_id
      );

     strMessaggio:='Inserimento fase_bil_t_gest_apertura_vincoli - FINE inserimenti - caso 3';
     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;




     strMessaggio:='Inserimento fase_bil_t_gest_apertura_vincoli - FINE inserimenti';
     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;


     codResult:=null;
	 strMessaggio:='Verifica inserimento dati in fase_bil_t_gest_apertura_vincoli.';
	 select  1 into codResult
     from fase_bil_t_gest_apertura_vincoli vinc
     where vinc.fase_bil_elab_id=faseBilElabId
     and   vinc.data_cancellazione is null
     and   vinc.validita_fine is null;

     if codResult is null then
     	raise exception ' Nessun inserimento effettuato.';
     end if;


     strMessaggio:='Aggiornamento stato fase bilancio IN-1.';
     update fase_bil_t_elaborazione fase
     set fase_bil_elab_esito='IN-1',
         fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_VINCOLI||' IN CORSO IN-1.POPOLA VINCOLI.'
     where fase.fase_bil_elab_id=faseBilElabId;


     faseBilElabRetId:=faseBilElabId;
     codiceRisultato:=0;
     messaggioRisultato:=strMessaggioFinale||' FINE';
     return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 50);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 50) ;
        codiceRisultato:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;
--SIAC -5852 FINE

-- SIAC-5877: aggiornamento da parte del CSI. - Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR023_Allegato_7_spese_titolo_macroaggregato" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_pluriennale varchar = 'S'::character varying
)
RETURNS TABLE (
  bil_anno varchar,
  titusc_tipo_code varchar,
  titusc_tipo_desc varchar,
  titusc_code varchar,
  titusc_desc varchar,
  macroag_tipo_code varchar,
  macroag_tipo_desc varchar,
  macroag_code varchar,
  macroag_desc varchar,
  macroag_id numeric,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  spesa_ricorrente_anno numeric,
  spesa_ricorrente_anno1 numeric,
  spesa_ricorrente_anno2 numeric
) AS
$body$
DECLARE
classifBilRec record;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
elemTipoCode_UG	varchar;
TipoImpstanzresidui varchar;
anno_bil_impegni	varchar;
tipo_capitolo	varchar;
missione_tipo_code varchar;
missione_tipo_desc varchar;
missione_code varchar;
missione_desc varchar;
programma_tipo_code varchar;
programma_tipo_desc varchar;
programma_code varchar;
programma_desc varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
importo integer :=0;
user_table	varchar;
cap_std	varchar;
cap_fpv	varchar;
cap_fsc	varchar;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
elemTipoCode:='CAP-UP'; -- tipo capitolo previsione
elemTipoCode_UG:='CAP_UG';	--- Capitolo gestione


anno_bil_impegni:= ((p_anno::INTEGER)-1)::VARCHAR;

cap_std:='STD';
cap_fpv:='FPV';
cap_fsc:='FSC';


bil_anno='';
missione_tipo_code='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_code='';
programma_tipo_desc='';
programma_code='';
programma_desc='';
titusc_tipo_code='';
titusc_tipo_desc='';
titusc_code='';
titusc_desc='';
macroag_tipo_code='';
macroag_tipo_desc='';
macroag_code='';
macroag_desc='';
stanziamento_prev_anno=0;


select fnc_siac_random_user()
into	user_table;

/*
insert into siac_rep_tit_mac_riga
select v.*,user_table from
(SELECT titusc_tipo.classif_tipo_desc AS titusc_tipo_desc,
    titusc.classif_id AS titusc_id, titusc.classif_code AS titusc_code,
    titusc.classif_desc AS titusc_desc,
    macroaggr_tipo.classif_tipo_desc AS macroag_tipo_desc,
    macroaggr.classif_id AS macroag_id, macroaggr.classif_code AS macroag_code,
    macroaggr.classif_desc AS macroag_desc, macroaggr.ente_proprietario_id
FROM siac_t_class_fam_tree titusc_tree, siac_d_class_fam titusc_fam,
    siac_r_class_fam_tree titusc_r_cft, siac_t_class titusc,
    siac_d_class_tipo titusc_tipo, siac_d_class_tipo macroaggr_tipo,
    siac_t_class macroaggr
WHERE titusc_fam.classif_fam_desc::text = 'Spesa - TitoliMacroaggregati'::text
    AND titusc_tree.classif_fam_id = titusc_fam.classif_fam_id 
    AND titusc_r_cft.classif_fam_tree_id = titusc_tree.classif_fam_tree_id 
    AND titusc.classif_id = titusc_r_cft.classif_id_padre 
    AND titusc_tipo.classif_tipo_code::text = 'TITOLO_SPESA'::text 
    AND titusc.classif_tipo_id = titusc_tipo.classif_tipo_id 
    AND macroaggr_tipo.classif_tipo_code::text = 'MACROAGGREGATO'::text 
    AND macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id 
    AND titusc_r_cft.classif_id = macroaggr.classif_id 
    AND titusc.ente_proprietario_id = macroaggr.ente_proprietario_id 
    AND to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
		between macroaggr.validita_inizio and
		COALESCE(macroaggr.validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
    AND to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
		between titusc.validita_inizio and
		COALESCE(titusc.validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
    AND to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
		between titusc_r_cft.validita_inizio and
		COALESCE(titusc_r_cft.validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
ORDER BY titusc.classif_code, macroaggr.classif_code) v
--------siac_v_bko_titolo_macroaggregato v 
where v.ente_proprietario_id=p_ente_prop_id 
order by titusc_code,macroag_code;
*/


/* 29/09/2016: la query per caricare i dati di struttura e' stata sostituita
	da quella piu' completa che estrae anche i dati di missione e programma
    per poter escludere i titoli/missione che non sono corretti.

*/
with missione as 
(select 
e.classif_tipo_desc missione_tipo_desc,
a.classif_id missione_id,
a.classif_code missione_code,
a.classif_desc missione_desc,
a.validita_inizio missione_validita_inizio,
a.validita_fine missione_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_missioneprogramma--'00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
--and to_timestamp('01/01/'||p_anno,'dd/mm/yyyy') between  v.titusc_validita_inizio and COALESCE(v.titusc_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
, programma as (
select 
e.classif_tipo_desc programma_tipo_desc,
b.classif_id_padre missione_id,
a.classif_id programma_id,
a.classif_code programma_code,
a.classif_desc programma_desc,
a.validita_inizio programma_validita_inizio,
a.validita_fine programma_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_missioneprogramma--'00001'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not  null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
,
titusc as (
select 
e.classif_tipo_desc titusc_tipo_desc,
a.classif_id titusc_id,
a.classif_code titusc_code,
a.classif_desc titusc_desc,
a.validita_inizio titusc_validita_inizio,
a.validita_fine titusc_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolomacroaggregato--'00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id)
, macroag as (
select 
e.classif_tipo_desc macroag_tipo_desc,
b.classif_id_padre titusc_id,
a.classif_id macroag_id,
a.classif_code macroag_code,
a.classif_desc macroag_desc,
a.validita_inizio macroag_validita_inizio,
a.validita_fine macroag_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolomacroaggregato--'00002'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
insert into siac_rep_tit_mac_riga
select distinct  titusc.titusc_tipo_desc,
titusc.titusc_id,
titusc.titusc_code,
titusc.titusc_desc,
macroag.macroag_tipo_desc,
macroag.macroag_id,
macroag.macroag_code,
macroag.macroag_desc,
missione.ente_proprietario_id
,user_table
from missione , programma,titusc, macroag
    /* 29/09/2016: start filtro per mis-prog-macro*/
  , siac_r_class progmacro
    /*end filtro per mis-prog-macro*/
 where programma.missione_id=missione.missione_id
 and titusc.titusc_id=macroag.titusc_id
  /* 29/09/2016: start filtro per mis-prog-macro*/
 AND programma.programma_id = progmacro.classif_a_id
 AND titusc.titusc_id = progmacro.classif_b_id
 /* end filtro per mis-prog-macro*/ 
 and titusc.ente_proprietario_id=missione.ente_proprietario_id;


insert into siac_rep_cap_up
select 	0,
		macroaggr.classif_id,
        anno_eserc.anno anno_bilancio,
       	capitolo.*,
        ' ',
       user_table utente
from siac_t_bil bilancio,
	 siac_t_periodo anno_eserc,
     siac_d_class_tipo macroaggr_tipo,
     siac_t_class macroaggr,
	 siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     siac_r_bil_elem_class r_capitolo_macroaggr, 
	 siac_d_bil_elem_stato stato_capitolo, 
     siac_r_bil_elem_stato r_capitolo_stato,
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo
where 
    macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						and
    macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and
    capitolo.ente_proprietario_id=p_ente_prop_id      						and
    anno_eserc.anno= p_anno 												and
    bilancio.periodo_id=anno_eserc.periodo_id 								and
    capitolo.bil_id=bilancio.bil_id 										and
   	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    tipo_elemento.elem_tipo_code = elemTipoCode						     	and 
    capitolo.elem_id=r_capitolo_macroaggr.elem_id						and
     capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
	stato_capitolo.elem_stato_code	=	'VA'								and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and
    -- 05/08/2016: aggiunto FPVC
    cat_del_capitolo.elem_cat_code	in (cap_std, cap_fpv, cap_fsc,'FPVC')					and
	------cat_del_capitolo.elem_cat_code	=	'STD'								and	
    bilancio.data_cancellazione 				is null						and
	anno_eserc.data_cancellazione 				is null						and
    macroaggr_tipo.data_cancellazione 			is null						and
    macroaggr.data_cancellazione 				is null						and
	capitolo.data_cancellazione 				is null						and
	tipo_elemento.data_cancellazione 			is null						and
    r_capitolo_macroaggr.data_cancellazione 	is null						and 
	stato_capitolo.data_cancellazione 			is null						and 
    r_capitolo_stato.data_cancellazione 		is null						and
	cat_del_capitolo.data_cancellazione 		is null						and
    r_cat_capitolo.data_cancellazione 			is null;					-----	and    
    
insert into siac_rep_cap_up_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo)       
from 		siac_t_bil_elem_det 			capitolo_importi,
         	siac_d_bil_elem_det_tipo 		capitolo_imp_tipo,
         	siac_t_periodo 					capitolo_imp_periodo,
            siac_t_bil_elem 				capitolo,
             siac_d_bil_elem_tipo 			tipo_elemento,
             siac_t_bil 					bilancio,
	 		siac_t_periodo 					anno_eserc, 
			siac_d_bil_elem_stato 			stato_capitolo, 
            siac_r_bil_elem_stato 			r_capitolo_stato,
			siac_d_bil_elem_categoria 		cat_del_capitolo, 
            siac_r_bil_elem_categoria 		r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id  
    	and	anno_eserc.anno						=p_anno 												
    	and	bilancio.periodo_id					=anno_eserc.periodo_id 								
        and	capitolo.bil_id						=bilancio.bil_id 			 
        and	capitolo.elem_id					=capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		=elemTipoCode
        and	capitolo_importi.elem_det_tipo_id	=capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)       
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		-- 05/08/2016: aggiunto FPVC
        and cat_del_capitolo.elem_cat_code	in (cap_std, cap_fpv, cap_fsc,'FPVC')
		----------and	cat_del_capitolo.elem_cat_code		=	'STD'
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   	capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;

insert into siac_rep_cap_up_imp_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		stanziamento_prev_anno,
    	tb2.importo 	as		stanziamento_prev_anno1,
    	tb3.importo		as		stanziamento_prev_anno2,
   	 	0,
    	0,
    	0,
          0,0,0,0,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_up_imp tb1, siac_rep_cap_up_imp tb2, siac_rep_cap_up_imp tb3
	where			tb1.elem_id	=	tb2.elem_id								and	
        			tb2.elem_id	=	tb3.elem_id								and
        			tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp	AND
        			tb2.periodo_anno = annoCapImp1	AND	tb1.tipo_imp =	tb2.tipo_imp	AND
        			tb3.periodo_anno = annoCapImp2	AND	tb2.tipo_imp =	tb3.tipo_imp
                    and tb1.utente 	= 	tb2.utente	
        			and	tb2.utente	=	tb3.utente
        			and	tb3.utente	=	user_table;
        
--------------  NON RICORRENTI    ----------------------------------------------


insert into siac_rep_up_imp_ricorrenti
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo)       
from 		siac_t_bil_elem_det 			capitolo_importi,
         	siac_d_bil_elem_det_tipo 		capitolo_imp_tipo,
         	siac_t_periodo 					capitolo_imp_periodo,
            siac_t_bil_elem 				capitolo,
            siac_d_bil_elem_tipo 			tipo_elemento,
            siac_t_bil 						bilancio,
	 		siac_t_periodo 					anno_eserc,
            siac_d_bil_elem_stato			stato_capitolo, 
            siac_r_bil_elem_stato 			r_capitolo_stato,
			siac_d_bil_elem_categoria 		cat_del_capitolo, 
            siac_r_bil_elem_categoria 		r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id  
    	/*and	capitolo_importi.ente_proprietario_id =capitolo_imp_tipo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id =capitolo_imp_periodo.ente_proprietario_id
        and capitolo_importi.ente_proprietario_id=capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id=tipo_elemento.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id=bilancio.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id=anno_eserc.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id=stato_capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id=r_capitolo_stato.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id=cat_del_capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id=r_cat_capitolo.ente_proprietario_id*/
        and	anno_eserc.anno						=p_anno 												
    	and	bilancio.periodo_id					=anno_eserc.periodo_id 								
        and	capitolo.bil_id						=bilancio.bil_id 			 
        and	capitolo.elem_id					=capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		=elemTipoCode
        and	capitolo_importi.elem_det_tipo_id	=capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp, annoCapImp1, annoCapImp2)
        and	capitolo.elem_id					=r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code		='VA'
		and	capitolo.elem_id					=r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code		in (cap_std, cap_fpv, cap_fsc,'FPVC')
        and capitolo_imp_tipo.elem_det_tipo_code	= TipoImpComp
        and capitolo_importi.elem_id    not in
        (select r_class.elem_id   
        from  	siac_r_bil_elem_class	r_class,
				siac_t_class 			b,
        		siac_d_class_tipo 		c
		where 	b.classif_id 		= 	r_class.classif_id
		and 	b.classif_tipo_id 	= 	c.classif_tipo_id
		and 	c.classif_tipo_code  = 'RICORRENTE_SPESA'
        and		b.classif_desc	=	'Ricorrente'
        and	r_class.data_cancellazione				is null
        and	b.data_cancellazione					is null
        and c.data_cancellazione					is null)
        /*
        and capitolo_importi.elem_id   in
        	(select attributo_capitolo.elem_id 
        	from 	siac_r_bil_elem_attr attributo_capitolo, 
             		siac_t_attr elenco_attributi
        	where 
        		elenco_attributi.attr_code ='FlagSpeseRicorrenti' 					and
      			elenco_attributi.attr_id = attributo_capitolo.attr_id)      */    
       and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        /*and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
    	and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
    	and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())*/
    group by  capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by  capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;


insert into siac_rep_up_imp_ricorrenti_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		spesa_ricorrente_anno,
    	tb2.importo 	as		spesa_ricorrente_anno1,
    	tb3.importo		as		spesa_ricorrente_anno2,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_up_imp_ricorrenti tb1, siac_rep_up_imp_ricorrenti tb2, siac_rep_up_imp_ricorrenti tb3
	where			tb1.elem_id	=	tb2.elem_id								and	
        			tb1.elem_id	=	tb3.elem_id								and
        			tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp	AND
        			tb2.periodo_anno = annoCapImp1	AND	tb1.tipo_imp =	tb2.tipo_imp	AND
        			tb3.periodo_anno = annoCapImp2	AND	tb2.tipo_imp =	tb3.tipo_imp
                    and tb1.utente 	= 	tb2.utente	
        			and	tb2.utente	=	tb3.utente
        			and	tb3.utente	=	user_table;
 

--------------------------------------------------------------------------------

for classifBilRec in
select 	v1.titusc_tipo_desc				titusc_tipo_desc,
		v1.titusc_code					titusc_code,
		v1.titusc_desc					titusc_desc,
		v1.macroag_tipo_desc			macroag_tipo_desc,
		v1.macroag_code					macroag_code,
		v1.macroag_desc					macroag_desc,
    	tb.bil_anno   					BIL_ANNO,
        COALESCE(sum(tb1.stanziamento_prev_anno),0)		stanziamento_prev_anno,
        COALESCE(sum(tb1.stanziamento_prev_anno1),0)	stanziamento_prev_anno1,
        COALESCE(sum(tb1.stanziamento_prev_anno2),0)	stanziamento_prev_anno2,
        COALESCE (sum(tb2.spesa_ricorrente_anno),0)		spesa_ricorrente_anno,
		COALESCE (sum(tb2.spesa_ricorrente_anno1),0)	spesa_ricorrente_anno1,
		COALESCE (sum(tb2.spesa_ricorrente_anno2),0)	spesa_ricorrente_anno2  
from   
	siac_rep_tit_mac_riga v1
			FULL  join siac_rep_cap_up tb
         	-----LEFT  join siac_rep_cap_up tb
           on    	(v1.macroag_id	= tb.macroaggregato_id
           			and v1.ente_proprietario_id=p_ente_prop_id
					------and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)     
            LEFT	join    siac_rep_cap_up_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id
            	AND tb1.utente=tb.utente
                and tb.utente=user_table)   
            left 	join	siac_rep_up_imp_ricorrenti_riga	tb2	
            on	(tb2.elem_id	=	tb.elem_id
            AND tb2.utente=tb.utente
                and tb.utente=user_table)   
    where v1.utente = user_table 	 	
    group by 
    		v1.titusc_tipo_desc,				
			v1.titusc_code,				
        	v1.titusc_desc,					
            v1.macroag_tipo_desc,			
			v1.macroag_code,				
			v1.macroag_desc,		
    		tb.bil_anno   				
    order by titusc_code,macroag_code
loop
  titusc_tipo_desc:= classifBilRec.titusc_tipo_desc;
  titusc_code:= classifBilRec.titusc_code;
  titusc_desc:= classifBilRec.titusc_desc;
  macroag_tipo_desc:= classifBilRec.macroag_tipo_desc;
  macroag_code:= classifBilRec.macroag_code;
  macroag_desc:= classifBilRec.macroag_desc;
  bil_anno:=classifBilRec.bil_anno;
  stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
  spesa_ricorrente_anno:=classifBilRec.spesa_ricorrente_anno;
  IF p_pluriennale = 'N' THEN  
    stanziamento_prev_anno1:=0;
    stanziamento_prev_anno2:=0;  
    spesa_ricorrente_anno1:=0;
    spesa_ricorrente_anno2:=0;    
  ELSE
    stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
    stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;  
    spesa_ricorrente_anno1:=classifBilRec.spesa_ricorrente_anno1;
    spesa_ricorrente_anno2:=classifBilRec.spesa_ricorrente_anno2;  
  END IF;

  return next;
  bil_anno='';
  titusc_tipo_code='';
  titusc_tipo_desc='';
  titusc_code='';
  titusc_desc='';
  macroag_tipo_code='';
  macroag_tipo_desc='';
  macroag_code='';
  macroag_desc='';
  stanziamento_prev_anno=0;
  stanziamento_prev_anno1=0;
  stanziamento_prev_anno2=0;
  spesa_ricorrente_anno=0;
  spesa_ricorrente_anno1=0;
  spesa_ricorrente_anno2=0;


end loop;

raise notice 'fine OK';
delete from siac_rep_tit_mac_riga				where utente=user_table;
delete from siac_rep_cap_up 					where utente=user_table;
delete from siac_rep_cap_up_imp 				where utente=user_table;
delete from siac_rep_cap_up_imp_riga 			where utente=user_table;
delete from siac_rep_up_imp_ricorrenti 			where utente=user_table;
delete from siac_rep_up_imp_ricorrenti_riga 	where utente=user_table; 

exception
when no_data_found THEN
raise notice 'nessun dato trovato per struttura bilancio';
return;
when others  THEN
RTN_MESSAGGIO:='struttura bilancio altro errore';
RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- SIAC-5877: aggiornamento da parte del CSI. - Maurizio - FINE

-- SIAC-5908: aggiornamento da parte del CSI -  Maurizio  - INIZIO

CREATE OR REPLACE FUNCTION siac.fnc_siac_disponibilitaincassaremovgest (
  movgest_ts_id_in integer
)
RETURNS numeric AS
$body$
DECLARE
number_out numeric;
tot_imp_ts numeric;
tot_imp_ord numeric;
tot_imp_subdoc numeric;
tot_imp_ord_sudoc numeric;
tot_imp_predoc numeric;
tot_mod_prov numeric;

BEGIN

--number_out:=1000.3;
number_out:=0.0;
tot_imp_ts:=0.0;
tot_imp_ord:=0.0;
tot_imp_subdoc:=0.0;
tot_imp_ord_sudoc:=0.0;
tot_imp_predoc:=0.0;

--SET TIME ZONE 'CET';


  
    select sum(e.movgest_ts_det_importo)
    into tot_imp_ts
    from siac_t_movgest_ts a,
         siac_d_movgest_ts_tipo b,
         siac_t_movgest c,
         siac_d_movgest_tipo d,
         siac_t_movgest_ts_det e,
         siac_d_movgest_ts_det_tipo f
    where a.movgest_ts_id = movgest_ts_id_in and
          a.movgest_ts_tipo_id = b.movgest_ts_tipo_id and
          a.movgest_id = c.movgest_id and
          c.movgest_tipo_id = d.movgest_tipo_id and
          e.movgest_ts_id = a.movgest_ts_id and
          f.movgest_ts_det_tipo_id = e.movgest_ts_det_tipo_id and
          f.movgest_ts_det_tipo_code = 'A' and
          a.data_cancellazione is null and
          now() between a.validita_inizio and
          coalesce(a.validita_fine, now()) and
          b.data_cancellazione is null and
          now() between b.validita_inizio and
          coalesce(b.validita_fine, now()) and
          c.data_cancellazione is null and
          now() between c.validita_inizio and
          coalesce(c.validita_fine, now()) and
          d.data_cancellazione is null and
          now() between d.validita_inizio and
          coalesce(d.validita_fine, now()) and
          e.data_cancellazione is null and
          now() between e.validita_inizio and
          coalesce(e.validita_fine, now()) and
          f.data_cancellazione is null and
          now() between f.validita_inizio and
          coalesce(f.validita_fine, now());

-- somma importoAttuale ordinativi  : in stato <> ANNULLATO

 select coalesce(sum(c.ord_ts_det_importo), 0)
 into tot_imp_ord
 from siac_r_ordinativo_ts_movgest_ts a,
      siac_t_ordinativo_ts b,
      siac_t_ordinativo_ts_det c,
      siac_d_ordinativo_ts_det_tipo d,
      siac_t_ordinativo e,
      siac_d_ordinativo_stato f,
      siac_r_ordinativo_stato g,
      siac_t_movgest_ts h
 where 
       --a.movgest_ts_id = movgest_ts_id_in  and
       (
       h.movgest_ts_id = movgest_ts_id_in 
       or h.movgest_ts_id_padre = movgest_ts_id_in
       ) 
       AND
       a.movgest_ts_id=h.movgest_ts_id and
       a.ord_ts_id = b.ord_ts_id and
       c.ord_ts_id = b.ord_ts_id and
       c.ord_ts_det_tipo_id = d.ord_ts_det_tipo_id and
       d.ord_ts_det_tipo_code = 'A' and
       e.ord_id = b.ord_id and
       e.ord_id = g.ord_id and
       g.ord_stato_id = f.ord_stato_id and
       f.ord_stato_code != 'A' and
       a.data_cancellazione is null and
       now() between a.validita_inizio and
       coalesce(a.validita_fine, now()) and
       b.data_cancellazione is null and
       now() between b.validita_inizio and
       coalesce(b.validita_fine, now()) and
       c.data_cancellazione is null and
       now() between c.validita_inizio and
       coalesce(c.validita_fine, now()) and
       d.data_cancellazione is null and
       now() between d.validita_inizio and
       coalesce(d.validita_fine, now()) and
       e.data_cancellazione is null and
       now() between e.validita_inizio and
       coalesce(e.validita_fine, now()) and
       f.data_cancellazione is null and
       now() between f.validita_inizio and
       coalesce(f.validita_fine, now()) and
       g.data_cancellazione is null and
       now() between g.validita_inizio and
       coalesce(g.validita_fine, now());


-- somma (importo - importoDaDedurre) subdocumenti di entrata collegati al movgest:  in stato <> A

 select coalesce(sum(a1.subdoc_importo - coalesce(a1.subdoc_importo_da_dedurre,0)),0) into tot_imp_subdoc
 from
    siac_r_subdoc_movgest_ts a, siac_t_subdoc a1,  siac_t_doc a2, 
    siac_d_doc_stato a3, siac_r_doc_stato a4 , siac_d_doc_tipo a5
    where
    a.movgest_ts_id =  movgest_ts_id_in--172
    and a.subdoc_id = a1.subdoc_id
    and a1.doc_id = a2.doc_id
    and a4.doc_id = a2.doc_id
    and a4.doc_stato_id = a3.doc_stato_id
    and a3.doc_stato_code != 'A' and  a3.doc_stato_code != 'ST'
    and a2.doc_tipo_id=a5.doc_tipo_id
    and a5.doc_tipo_code <> 'NCV' 
    and a5.data_cancellazione is null
    and a.data_cancellazione is null
    and now() between  a.validita_inizio 
    and coalesce(a.validita_fine, now())
   	and a1.data_cancellazione is null
    and now() between  a1.validita_inizio 
    and coalesce(a1.validita_fine, now()) 
   	and a2.data_cancellazione is null
    and now() between  a2.validita_inizio 
    and coalesce(a2.validita_fine, now()) 
   	and a3.data_cancellazione is null
    and now() between  a3.validita_inizio
     and coalesce(a3.validita_fine, now()) 
       and a4.data_cancellazione is null
    and now() between  a4.validita_inizio 
    and coalesce(a4.validita_fine, now())
    ;

-- somma (importo) degli ordinativi collegate a subdocumenti di entrata collegati al movgest iniziale

select coalesce(sum(c.ord_ts_det_importo),0)  into tot_imp_ord_sudoc
    from
    siac_r_ordinativo_ts_movgest_ts a, siac_t_ordinativo_ts b, siac_t_ordinativo_ts_det c,
    siac_r_subdoc_ordinativo_ts e,siac_d_ordinativo_ts_det_tipo f, siac_t_ordinativo g, 
    siac_d_ordinativo_stato h, 
    siac_r_ordinativo_stato i
    where
    a.movgest_ts_id =  movgest_ts_id_in--172
    and a.ord_ts_id = e.ord_ts_id
    and a.ord_ts_id = b.ord_ts_id
    and c.ord_ts_id = b.ord_ts_id
    and g.ord_id=b.ord_id
    and i.ord_id=g.ord_id
    and h.ord_stato_id=i.ord_stato_id
    and h.ord_stato_code<>'A'
    and f.ord_ts_det_tipo_id=c.ord_ts_det_tipo_id 
    and f.ord_ts_det_tipo_code='A'
    and now() between  i.validita_inizio and coalesce(i.validita_fine, now()) 
    and now() between  a.validita_inizio and coalesce(a.validita_fine, now()) 
    and now() between  b.validita_inizio and coalesce(b.validita_fine, now()) 
    and now() between  c.validita_inizio and coalesce(c.validita_fine, now()) 
    and now() between  e.validita_inizio and coalesce(e.validita_fine, now()) 
    and a.data_cancellazione is null
    and b.data_cancellazione is null
    and c.data_cancellazione is null
    and e.data_cancellazione is null
    and f.data_cancellazione is null
    and g.data_cancellazione is null
    and h.data_cancellazione is null
    and i.data_cancellazione is null
    ;


-- somma predoc collegati al movgest : in stato I o C
 select coalesce(sum (a1.predoc_importo),0)  into tot_imp_predoc
 from
    siac_r_predoc_movgest_ts a, siac_t_predoc a1, siac_d_predoc_stato a3, siac_r_predoc_stato a4
    where
    a.movgest_ts_id = movgest_ts_id_in
    and a.predoc_id = a1.predoc_id
    and a1.predoc_id = a4.predoc_id
    and a4.predoc_stato_id = a3.predoc_stato_id
    and (a3.predoc_stato_code 
    = 'I' or  a3.predoc_stato_code = 'C')
    and a.data_cancellazione is null
    and now() between  a.validita_inizio
    and coalesce(a.validita_fine, now()) 
   	and a1.data_cancellazione is null
    and now() between  a1.validita_inizio
    and coalesce(a1.validita_fine, now()) 
 	and a3.data_cancellazione is null
    and now() between  a3.validita_inizio
    and coalesce(a3.validita_fine, now()) 
    and a4.data_cancellazione is null
    and now() between  a4.validita_inizio
    and coalesce(a4.validita_fine, now()) 
    ;


--nuova sezione CR 740

select coalesce(sum(c.movgest_ts_det_importo),0) into tot_mod_prov
from siac_t_modifica a, siac_r_modifica_stato b,
siac_t_movgest_ts_det_mod c, siac_t_movgest_ts_det d,
siac_t_movgest_ts e, siac_d_modifica_stato f, siac_t_atto_amm g,
siac_r_atto_amm_stato h, siac_d_atto_amm_stato i
where
e.movgest_ts_id = movgest_ts_id_in
and f.mod_stato_code = 'V' -- la modifica deve essere valida
and i.attoamm_stato_code = 'PROVVISORIO' -- atto provvisorio
and c.movgest_ts_det_importo > 0 -- importo positivo
--
and a.mod_id = b.mod_id
and c.mod_stato_r_id = b.mod_stato_r_id
and d.movgest_ts_det_id = c.movgest_ts_det_id
and e.movgest_ts_id = d.movgest_ts_id
and f.mod_stato_id = b.mod_stato_id
and a.attoamm_id = g.attoamm_id
and g.attoamm_id = h.attoamm_id
and h.attoamm_stato_id = i.attoamm_stato_id
-- date
and a.data_cancellazione is null
and now() between a.validita_inizio and coalesce(a.validita_fine, now())
and b.data_cancellazione is null
and now() between b.validita_inizio and coalesce(b.validita_fine, now())
and c.data_cancellazione is null
and now() between c.validita_inizio and coalesce(c.validita_fine, now())
and d.data_cancellazione is null
and now() between d.validita_inizio and coalesce(d.validita_fine, now())
and e.data_cancellazione is null
and now() between e.validita_inizio and coalesce(e.validita_fine, now())
and f.data_cancellazione is null
and now() between f.validita_inizio and coalesce(f.validita_fine, now())
and g.data_cancellazione is null
and now() between g.validita_inizio and coalesce(g.validita_fine, now())
and h.data_cancellazione is null
and now() between h.validita_inizio and coalesce(h.validita_fine, now())
and i.data_cancellazione is null;

raise notice 'tot_mod_prov:%',tot_mod_prov;  


--importoattuale

number_out:=tot_imp_ts -  tot_imp_ord  - (tot_imp_subdoc - tot_imp_ord_sudoc) - tot_imp_predoc   ;

number_out:=number_out - tot_mod_prov;
return number_out;



END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

-- SIAC-5908: aggiornamento da parte del CSI -  Maurizio  - FINE


-- update azione 
update siac_t_azione set azione_code='OP-ENT-gestisciAccertamentoRIACC'
where azione_code='OP-SPE-gestisciAccertamentoRIACC';