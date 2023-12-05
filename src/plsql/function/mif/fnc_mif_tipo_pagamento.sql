/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION fnc_mif_tipo_pagamento( ordinativoId integer,
												   codicePaese varchar,
                                                   codiceItalia varchar,
                                                   codiceAreaSepa varchar,
                                                   esisteContoCorrente boolean,
                                                   esisteBic boolean,
                                                   esisteDenominazioneBanca boolean,
                                                   accreditoCodeCB varchar,
                                                   accreditoCodeCO varchar,
                                                   isManLeva boolean,
 												   accreditoTipoId INTEGER,
                                                   dataElaborazione timestamp,
                                                   dataFineVal timestamp,
                                                   enteProprietarioId integer,
												   out codeTipoPagamento varchar,
                                                   out descTipoPagamento varchar,
                                                   out defRifDocEsterno boolean)
RETURNS record AS
$body$
DECLARE

strMessaggio varchar(1500):=null;

isSepa boolean:=false;
isProvvisori boolean :=false;
isAllegatoCartaceo boolean :=false;

codAreaSepa VARCHAR(50):=null;
accreditoTipoCode varchar(50):=null;
checkDati integer:=null;
accreditoCodeTes varchar(50):=null;
accreditoTipoOilId integer :=null;
accreditoCodePag varchar(50):=null;
accreditoDescPag varchar(200):=null;

ALLEG_CART_ATTR CONSTANT VARCHAR:='flagAllegatoCartaceo';

BEGIN

 codeTipoPagamento:=null;
 descTipoPagamento:=null;
 defRifDocEsterno:=false;



 -- codiceItalia valore presente in param
 -- codicePaese valorizzato se presente Iban
 -- codiceAreaSepa letto in param
 -- isManLeva letto da ente_oil
 -- esisteContoCorrente --> true se esiste contocorrente
 -- esisteBic --> true se esiste bic
 -- esisteDenominazioneBanca --> banca_denominazione valorizzato


-- raise notice 'ordinativoId=% ',ordinativoId;
-- raise notice 'codicePaese=% ',codicePaese;
-- raise notice 'codiceItalia=% ',codiceItalia;
-- raise notice 'codiceAreaSepa=% ',codiceAreaSepa;


 if codicePaese is not null and codicePaese!=codiceItalia then
    strMessaggio:='Lettura tipo pagamento ordinativo [siac_t_sepa].';
 	select distinct 1 into checkDati
    from siac_t_sepa sepa
    where sepa.sepa_iso_code=codicePaese
    and   sepa.ente_proprietario_id=enteProprietarioId
    and   sepa.data_cancellazione is null
 	and   date_trunc('day',dataElaborazione)>=date_trunc('day',sepa.validita_inizio)
-- 	and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(sepa.validita_fine,dataFineVal)); 19.01.2017
 	and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(sepa.validita_fine,dataElaborazione));

    if checkDati is not null then
    	isSepa:=true;
    end if;

    checkDati:=null;
    strMessaggio:='Lettura tipo pagamento ordinativo [siac_r_ordinativo_prov_cassa].';
    select distinct 1 into checkDati
    from siac_r_ordinativo_prov_cassa prov
    where prov.ord_id=ordinativoId
    and   prov.data_cancellazione is null
    and   prov.validita_fine is null;

    if checkDati is not null then
    	isProvvisori  :=true;
    end if;
 end if;

 checkDati:=null;
 strMessaggio:='Lettura tipo pagamento ordinativo [siac_r_ordinativo_attr].';
 select 1 into checkDati
 from siac_r_ordinativo_attr rattr, siac_t_attr attr
 where rattr.ord_id=ordinativoId
 and   rattr.boolean='S'
 and   rattr.data_cancellazione is null
 and   rattr.validita_fine is null
 and   attr.attr_id=rattr.attr_id
 and   attr.attr_code=ALLEG_CART_ATTR
 and   attr.data_cancellazione is null
 and   attr.validita_fine is null;

 if checkDati is not null then
  	isAllegatoCartaceo  :=true;
 end if;

 strMessaggio:='Lettura tipo pagamento ordinativo.';
-- raise notice 'isProvvisori=% ',isProvvisori;
--  raise notice 'isSepa=% ',isSepa;

 if codicePaese is not  null and  codicePaese!=codiceItalia and isSepa=true and isProvvisori=false then
 	-- lettura tabella di decodifica con CB ( valore presente in param), oil_area=SEPA
    accreditoCodeTes:=accreditoCodeCB;
    codAreaSepa:=codiceAreaSepa;
	isAllegatoCartaceo  :=false; -- forzato a false
 end if;


 if codicePaese is not  null and  codicePaese!=codiceItalia and isSepa=true and isProvvisori=true then
 	-- lettura tabella di decodifica CO ( valore presente in param )
    accreditoCodeTes:=accreditoCodeCO;
 end if;

 if codicePaese is not  null and  codicePaese!=codiceItalia and isSepa=false and
    isManleva=false then
    -- lettura tabella di decodifica CO ( valore presente in param )
    accreditoCodeTes:=accreditoCodeCO;
    isAllegatoCartaceo  :=true; -- forzato a true
 end if;

 if codicePaese is not  null and  codicePaese!=codiceItalia and isSepa=false and
    isManLeva=true and isProvvisori=false and isAllegatoCartaceo=false and
    esisteContoCorrente=true and esisteBic=true and esisteDenominazioneBanca=true then
 	-- lettura tabella di decodifica con CB ( valore presente in param), oil_area=SEPA
    accreditoCodeTes:=accreditoCodeCB;
    codAreaSepa:=codiceAreaSepa;
 end if;

 if codicePaese is not  null and  codicePaese!=codiceItalia and isSepa=false and
    isManLeva=true and
    (isProvvisori=false and isAllegatoCartaceo=false and
     esisteContoCorrente=true and esisteBic=true and esisteDenominazioneBanca=true)=false then
 	-- lettura tabella di decodifica con CO ( valore presente in param)
    accreditoCodeTes:=accreditoCodeCO;
    isAllegatoCartaceo  :=true; -- forzato a true
 end if;

 -- questo vale anche per tutti gli altri casi non previsti sopra
 --if coalesce(codicePaese,' ')=codiceItalia THEN
 	-- lettura tabella di decodifica
 --end if;
 if accreditoCodeTes is null then
    accreditoTipoOilId:=accreditoTipoId;
 else
    -- lettura di accredito_tipo_id per lettura in accredito_tipo
	strMessaggio:='Lettura tipo pagamento ordinativo [siac_d_accredito_tipo] accredito_tipo_code='||accreditoCodeTes||'.';

	select tipo.accredito_tipo_id into accreditoTipoOilId
	from siac_d_accredito_tipo tipo
	where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.accredito_tipo_code=accreditoCodeTes
	and   tipo.data_cancellazione is null
	and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
--	and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal)); 19.01.2017
	and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

	 if accreditoTipoOilId is null then
 		RAISE EXCEPTION ' Accredito tipo non trovato.';
	 end if;
 end if;

 -- lettura di accredito_tipo_id per lettura in accredito_tipo_oil
 strMessaggio:='Lettura tipo pagamento ordinativo [siac_d_accredito_tipo_oil].';
 select oil.accredito_tipo_oil_code,oil.accredito_tipo_oil_desc into accreditoCodePag,accreditoDescPag
 from siac_d_accredito_tipo_oil oil, siac_r_accredito_tipo_oil raccre
 where raccre.accredito_tipo_id=accreditoTipoOilId
 and   raccre.data_cancellazione is null
 and   raccre.validita_fine is null
 and   oil.accredito_tipo_oil_id=raccre.accredito_tipo_oil_id
 and   coalesce(oil.accredito_tipo_oil_area,'ITALIA')=coalesce(codAreaSepa,'ITALIA')
 and   oil.data_cancellazione is null
 and   date_trunc('day',dataElaborazione)>=date_trunc('day',oil.validita_inizio)
-- and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(oil.validita_fine,dataFineVal)); 19.01.2017
 and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(oil.validita_fine,dataElaborazione));




 codeTipoPagamento:=accreditoCodePag;
 descTipoPagamento:=accreditoDescPag;
 defRifDocEsterno:= isAllegatoCartaceo;
--  raise notice 'accreditoCodePag=% ',accreditoCodePag;
--  raise notice 'descTipoPagamento=% ',accreditoDescPag;


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