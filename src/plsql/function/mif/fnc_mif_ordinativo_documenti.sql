/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION fnc_mif_ordinativo_documenti( ordinativoId integer,
 													     numeroDocumenti integer,
                                                         tipiDocumento varchar,
                                                   	     enteProprietarioId integer,
                                                         dataElaborazione timestamp,
                                                         dataFineVal timestamp)
RETURNS TABLE
(
	documentiColl varchar
 ) AS
$body$
DECLARE

strMessaggio varchar(1500):=null;
documentiRec record;
--documentiColl varchar(1000):=null;
documentiCollTemp varchar(500):=null;
numeroDocs integer:=1;
BEGIN

 strMessaggio:='Lettura documenti collegati.';
 documentiColl:=null;

 for documentiRec in
 ( select doc.doc_anno annoDoc, doc.doc_numero numeroDoc, tipo.doc_tipo_code tipoDoc,
          subdoc.subdoc_numero::varchar numeroSubDoc,
          lpad(extract('day' from doc.doc_data_emissione)::varchar,2,'0')||'/'||
          lpad(extract('month' from doc.doc_data_emissione)::varchar,2,'0')||'/'||
          extract('year' from doc.doc_data_emissione) dataDoc,
          subdoc.subdoc_importo importoDoc
   from siac_t_doc doc, siac_t_subdoc subdoc, siac_r_subdoc_ordinativo_ts subdocTs,
        siac_t_ordinativo_ts ordts, siac_d_doc_tipo tipo, fnc_mif_ordinativo_split_par(tipiDocumento) fnc
   where ordts.ord_id=ordinativoId
   and   subdocts.ord_ts_id=ordts.ord_ts_id
   and   subdoc.subdoc_id=subdocts.subdoc_id
   and   doc.doc_id=subdoc.doc_id
   and   tipo.doc_tipo_id=doc.doc_tipo_id
   and   tipo.doc_tipo_code = fnc.elemPar
   and   ordts.data_cancellazione is null and ordts.validita_fine is null
   and   subdocts.data_cancellazione is null AND subdocts.validita_fine is null
   and   subdoc.data_cancellazione is null and subdoc.validita_fine is null
   and   doc.data_cancellazione is null and doc.validita_fine is null
   and   tipo.data_cancellazione is null
   and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
--   and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal)) 19.01.2017
   and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione))
   order by 1,2,3,4
 )
 loop
 	documentiCollTemp:='N. '||documentiRec.annoDoc||'/'||
    				   documentiRec.numeroDoc||'/'||
                       documentiRec.tipoDoc||'/'||
                       documentiRec.numeroSubDoc;
/*    if length(documentiCollTemp) <=19 then
    	documentiCollTemp:=documentiCollTemp||' '||documentiRec.dataDoc;
    end if; JIRA SIAC-XXXX 19.02.2016 Sofia */

    -- JIRA SIAC-XXXX 19.02.2016 Sofia
    if length(documentiCollTemp||' '||documentiRec.dataDoc) <=30 then
    	documentiCollTemp:=documentiCollTemp||' '||documentiRec.dataDoc;
    end if;


/**    if length(documentiCollTemp)<30 then
    	documentiCollTemp:=documentiCollTemp||' '||documentiRec.importoDoc;
    end if; JIRA SIAC-XXXX 19.02.2016 Sofia **/
    -- JIRA SIAC-XXXX 19.02.2016 Sofia


    --raise notice 'documentiCollTemp %', documentiCollTemp;
    exit when numeroDocs>numeroDocumenti;

    if length(documentiCollTemp)>=30 then
    	documentiCollTemp:=substring(documentiCollTemp from 1 for 30);
    end if;
    documentiColl:=documentiCollTemp;
  --  raise notice 'documentiColl %', documentiColl;
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