/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/



CREATE OR REPLACE FUNCTION siac.fnc_mif_isDocumentoCommerciale_e_splus( docId integer,
                                                                   parTipoCode varchar
)
RETURNS boolean AS
$body$
DECLARE

strMessaggio varchar(1500):=null;

isCommerciale boolean:=false;
docGruppoTipoId integer :=null;

docTipoCode  varchar(100):=null;

BEGIN


 select tipo.doc_tipo_code, tipo.doc_gruppo_tipo_id
        into docTipoCode , docGruppoTipoId
 from siac_t_doc doc,  siac_d_doc_tipo tipo
 where doc.doc_id=docId
 and   tipo.doc_tipo_id=doc.doc_tipo_id;

 if docTipoCode is not null
    and docTipoCode=parTipoCode then
    isCommerciale:=true;
 end if;


 return isCommerciale;




exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',coalesce(strMessaggio,'')||' '||coalesce(substring(upper(SQLERRM) from 1 for 1000),'');
        return isCommerciale;
    when TOO_MANY_ROWS THEN
        RAISE EXCEPTION '% Diverse righe lette.',coalesce(strMessaggio,'');
        return isCommerciale;
   when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',coalesce(strMessaggio,'');
        return isCommerciale;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',coalesce(strMessaggio,''),SQLSTATE,substring(SQLERRM from 1 for 1000);
        return isCommerciale;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;