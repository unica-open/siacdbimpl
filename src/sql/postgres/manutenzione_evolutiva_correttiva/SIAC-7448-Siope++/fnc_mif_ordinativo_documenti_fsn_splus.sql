/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_mif_ordinativo_documenti_fsn_splus( ordinativoId integer,
 													           numeroDocumenti integer,
                                                               tipiDocumento   varchar,
                                                               docAnalogico    varchar,
                                                               docElettronico    varchar,
                                                               attrCodeDataScad varchar,
                                                               naturaPag        varchar,
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
    importo_siope_split             varchar,
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
tipoDocElettronico  varchar(500):=null;


DOC_TIPO_ALG      CONSTANT varchar:='ALG';

numeroDocs integer:=1;

tipoDocFSN   varchar(10):=null;
importoDoc numeric:=0;
codiceFiscaleDef varchar(50):=null;


numeroFatturaFEL VARCHAR(100):=null;
numeroSDIFatturaFEL VARCHAR(100):=null;
importoFatturaFEL numeric:=null;

BEGIN

 strMessaggio:='Lettura documenti collegati.';


 tipoDocFSN:=trim (both ' ' from split_part(tipiDocumento,',',1));

 raise notice 'docAnalogico=%',docAnalogico;
 codiceFiscaleDef:=trim (both ' ' from split_part(docAnalogico,'|',2));
 docAnalogico:=trim (both ' ' from split_part(docAnalogico,'|',1));

 raise notice 'docAnalogico=%',docAnalogico;
 raise notice 'codiceFiscaleDef=%',codiceFiscaleDef;
 raise notice 'docElettronico=%',docElettronico;


 codice_ipa_ente_siope:=null;
 tipo_documento_siope:=null;
 tipo_documento_siope_a:=null;

 identificativo_lotto_sdi_siope:=null;
 tipo_documento_analogico_siope:=null;
 codice_fiscale_emittente_siope:=null;
 anno_emissione_fattura_siope:=null;
 numero_fattura_siope:=null;
 importo_siope:=null;
 importo_siope_split:=null;
 data_scadenza_pagam_siope:=null;
 motivo_scadenza_siope:=null;
 natura_spesa_siope:=null;



 strMessaggio:=strMessaggio||' Inizio ciclo lettura.';
 --raise notice 'strMessaggio =%',strMessaggio;



 for documentiRec in
 (
  select doc.doc_anno annoDoc, doc.doc_numero numeroDoc, tipo.doc_tipo_code tipoDoc,
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
        coalesce(sum(subdoc.subdoc_splitreverse_importo),0) importoSplitDoc
  from siac_t_doc doc, siac_t_subdoc subdoc, siac_r_subdoc_ordinativo_ts subdocTs,
       siac_t_ordinativo_ts ordts, siac_d_doc_tipo tipo,
       siac_r_doc_sog rsog, siac_t_soggetto sog
  where ordts.ord_id=ordinativoId
  and   subdocts.ord_ts_id=ordts.ord_ts_id
  and   subdoc.subdoc_id=subdocts.subdoc_id
  and   doc.doc_id=subdoc.doc_id
  and   tipo.doc_tipo_id=doc.doc_tipo_id
  and   fnc_mif_isDocumentoCommerciale_e_splus(doc.doc_id,tipoDocFSN)=true
  and   tipo.doc_tipo_code=tipoDocFSN
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
  order by 1,2,3,4,6,7,8
 )
 loop

    strMessaggio:='Lettura dati documento doc_id='||documentiRec.docId||'.';
    raise notice 'strMessaggio =%',strMessaggio;

    codice_ipa_ente_siope:=null;          -- ok! siac_t_doc.pccuff_id
    tipo_documento_siope:=null;           -- ok! siac_t_doc.siope_documento_tipo_id
    tipo_documento_siope_a:=null;         -- ok! siac_t_doc.siope_documento_tipo_id
    identificativo_lotto_sdi_siope:=null; -- ok! siac_t_doc.doc_sdi_lotto_siope
    tipo_documento_analogico_siope:=null; -- ok! solo per doc ANALOGICO doc.siope_documento_tipo_analogico_id
    codice_fiscale_emittente_siope:=null; -- ok!
    anno_emissione_fattura_siope:=null;   -- ok!
    numero_fattura_siope:=null;           -- ok!
    importo_siope:=null;                  -- ok!
    importo_siope_split:=null;            -- ok!
    data_scadenza_pagam_siope:=null;      -- dataScadenzaDopoSospensione ok!
    motivo_scadenza_siope:=null;          -- ok! siac_t_subdoc.siope_scadenza_motivo_id
    natura_spesa_siope:=null;             -- CORRENTE

	motivoScadenza:=null;
    dataScadDopoSosp:=null;
    tipoDocAnalogico:=null;

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

    /*if documentiRec.siopeDocTipoId is not null then
    	strMessaggio:='Lettura dati documento doc_id='||documentiRec.docId||'.'||' Lettura tipo documento siope [siac_d_siope_documento_tipo].';
		 --raise notice 'strMessaggio 3 =%',strMessaggio;

        select upper(tipo.siope_documento_tipo_desc_bnkit) into tipoDocAnalogico
        from siac_d_siope_documento_tipo tipo
        where tipo.siope_documento_tipo_id=documentiRec.siopeDocTipoId;

        if tipoDocAnalogico is not null   then
         if tipoDocAnalogico=docAnalogico then
        	  tipo_documento_siope_a:=docAnalogico; -- ANALOGICO
         else
              tipo_documento_siope:=tipoDocAnalogico;   -- ELETTRONCIO
         end if;
        end if;
    else tipo_documento_siope:=docElettronico;   -- ELETTRONCIO
    end if;*/

    if tipo_documento_siope is null then tipo_documento_siope:=docElettronico; end if;

	if tipo_documento_siope is not null and documentiRec.siopeSdiLotto is not null then
	  identificativo_lotto_sdi_siope:=documentiRec.siopeSdiLotto;
    end if;

    -- se documento analogico
    /*if tipo_documento_siope_a is not null and
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

      anno_emissione_fattura_siope:=documentiRec.annoDoc::varchar;
	end if;*/



    raise notice 'documentiRec.importoDoc=%',documentiRec.importoDoc;
    raise notice 'documentiRec.datascadDoc=%',documentiRec.datascadDoc;

    numero_fattura_siope:=documentiRec.numeroDoc;
    importo_siope:=documentiRec.importoDoc::varchar;
    importo_siope_split:=documentiRec.importoSplitDoc::varchar;




--    		 raise notice 'strMessaggio 3 =%',strMessaggio;




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

    natura_spesa_siope:=naturaPag;

	strMessaggio:='Lettura dati documento doc_id='||documentiRec.docId||'.'||' Lettura dati FEL [siac_r_doc_sirfel].';
    raise notice 'strmessaggio=%', strMessaggio;

    select fel.numero, abs(fel.importo_totale_documento), port.identificativo_sdi::varchar
    into   numeroFatturaFEL, importoFatturaFEL, numeroSDIFatturaFEL
	from siac_r_doc_sirfel rs,
	     sirfel_t_fattura fel,sirfel_t_portale_fatture port
	where rs.doc_id=documentiRec.docId
	and   fel.id_fattura=rs.id_fattura
    and   port.id_fattura=fel.id_fattura
	and   rs.data_cancellazione is null
	and   rs.validita_fine is null;
    if numeroFatturaFEL is null then continue; end if;

    raise notice 'numeroFatturaFEL=%',numeroFatturaFEL;
    raise notice 'importoFatturaFEL=%',importoFatturaFEL;
    raise notice 'numeroSDIFatturaFEL=%',numeroSDIFatturaFEL;

    numero_fattura_siope:=numeroFatturaFEL;
    importo_siope:=importoFatturaFEL::varchar;
    identificativo_lotto_sdi_siope:= numeroSDIFatturaFEL;

    -- se importo=0  non resistuisco dati
    if importo_siope::numeric =0 then
    	continue;
    end if;

    exit when numeroDocs>numeroDocumenti;

	return next;

    numeroDocs:=numeroDocs+1;
 end loop;

 raise notice 'numeroDocs %',numeroDocs;

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