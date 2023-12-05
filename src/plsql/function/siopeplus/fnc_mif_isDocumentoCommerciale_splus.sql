/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


DROP FUNCTION IF EXISTS siac.fnc_mif_isDocumentoCommerciale_splus
( 
 docId integer,
 fprTipoCode varchar,
 fatGruppoCode varchar,
 ncdGruppoCode varchar
 );

DROP FUNCTION IF EXISTS siac.fnc_mif_isDocumentoCommerciale_splus
( 
 docId integer,
 fprTipoCode varchar,
 fatGruppoCode varchar,
 ncdGruppoCode varchar,
 nteTipoCode varchar
 );


CREATE OR REPLACE FUNCTION siac.fnc_mif_isDocumentoCommerciale_splus
( 
docId integer,
fprTipoCode varchar,
fatGruppoCode varchar,
ncdGruppoCode varchar,
nteTipoCode varchar
)
RETURNS boolean AS
$body$
DECLARE

strMessaggio varchar(1500):=null;

isCommerciale boolean:=false;
docGruppoTipoId integer :=null;

docTipoCode  varchar(100):=null;
docGruppoTipoCode varchar(100):=null;
BEGIN


 select tipo.doc_tipo_code, tipo.doc_gruppo_tipo_id
        into docTipoCode , docGruppoTipoId
 from siac_t_doc doc,  siac_d_doc_tipo tipo
 where doc.doc_id=docId
 and   tipo.doc_tipo_id=doc.doc_tipo_id;

 if docGruppoTipoId is null
    and docTipoCode is not null
--    and docTipoCode=fprTipoCode then -- 29.03.2o23 Sofia Jira SIAC-8880
       and docTipoCode in (fprTipoCode,nteTipoCode) then    
    isCommerciale:=true;
 end if;

 if isCommerciale=false
    and docGruppoTipoId is not null then
    select gruppo.doc_gruppo_tipo_code into docGruppoTipoCode
    from siac_d_doc_gruppo gruppo
    where gruppo.doc_gruppo_tipo_id=docGruppoTipoId;

    if docGruppoTipoCode is not null
       and docGruppoTipoCode in (fatGruppoCode,ncdGruppoCode) then
       isCommerciale:=true;
    end if;
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


alter FUNCTION siac.fnc_mif_isDocumentoCommerciale_splus (  integer, varchar, varchar, varchar,varchar) owner to siac;