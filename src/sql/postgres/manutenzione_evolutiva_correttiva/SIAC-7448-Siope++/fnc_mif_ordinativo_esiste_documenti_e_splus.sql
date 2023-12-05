/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_mif_ordinativo_esiste_documenti_e_splus( ordinativoId integer,
                                                                      	     tipoDocumento   varchar,
                                                   	                  		 enteProprietarioId integer
                                                                            )
RETURNS boolean AS
$body$
DECLARE

strMessaggio varchar(1500):=null;

DOC_TIPO_ALG      CONSTANT varchar:='ALG';

numeroDocs integer:=1;
esisteDoc  boolean:=false;

BEGIN

 strMessaggio:='Lettura esistenza documenti collegati.';




  select doc.doc_id into numeroDocs
  from siac_t_doc doc, siac_t_subdoc subdoc, siac_r_subdoc_ordinativo_ts subdocTs,
       siac_t_ordinativo_ts ordts, siac_d_doc_tipo tipo
  where ordts.ord_id=ordinativoId
  and   subdocts.ord_ts_id=ordts.ord_ts_id
  and   subdoc.subdoc_id=subdocts.subdoc_id
  and   doc.doc_id=subdoc.doc_id
  and   tipo.doc_tipo_id=doc.doc_tipo_id
  and   fnc_mif_isDocumentoCommerciale_e_splus(doc.doc_id,tipoDocumento)=true
  and   tipo.doc_tipo_code!=DOC_TIPO_ALG
  and   ordts.data_cancellazione is null and ordts.validita_fine is null
  and   subdocts.data_cancellazione is null AND subdocts.validita_fine is null
  and   subdoc.data_cancellazione is null and subdoc.validita_fine is null
  and   doc.data_cancellazione is null and doc.validita_fine is null
  and   tipo.data_cancellazione is null
  and   date_trunc('day',now()::timestamp)>=date_trunc('day',tipo.validita_inizio)
  and   date_trunc('day',now()::timestamp)<=date_trunc('day',coalesce(tipo.validita_fine,now()::timestamp))
  limit 1;

  --raise notice 'numeroDocs %',numeroDocs;

  if coalesce(numerodocs,0)>=1 then esisteDoc:=true; end if;

  return esisteDoc;


exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',coalesce(strMessaggio,'')||' '||coalesce(substring(upper(SQLERRM) from 1 for 1000),'');
        return esisteDoc;
    when TOO_MANY_ROWS THEN
        RAISE EXCEPTION '% Diverse righe lette.',coalesce(strMessaggio,'');
        return esisteDoc;
   when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',coalesce(strMessaggio,'');
        return esisteDoc;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',coalesce(strMessaggio,''),SQLSTATE,substring(SQLERRM from 1 for 1000);
        return esisteDoc;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;