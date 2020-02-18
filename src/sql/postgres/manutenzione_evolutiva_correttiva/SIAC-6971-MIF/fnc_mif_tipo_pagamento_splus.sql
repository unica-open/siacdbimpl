/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿/*drop FUNCTION fnc_mif_tipo_pagamento_splus( ordinativoId integer,
												   codicePaese varchar,
                                                   codiceItalia varchar,
                                                   codiceAreaSepa varchar,
                                                   codiceAreaExtraSepa varchar,
                                                   accreditoCodeCB varchar,
                                                   accreditoCodeREG varchar,
                                                   tipoPagamCompensa varchar,
 												   accreditoTipoId INTEGER,
                                                   accreditoGruppoCode varchar,
                                                   importoOrd       numeric,
                                                   dataElaborazione timestamp,
                                                   dataFineVal timestamp,
                                                   enteProprietarioId integer,
												   out codeTipoPagamento varchar,
                                                   out descTipoPagamento varchar,
                                                   out defRifDocEsterno boolean);*/

CREATE OR REPLACE FUNCTION fnc_mif_tipo_pagamento_splus( ordinativoId integer,
												   codicePaese varchar,
                                                   codiceItalia varchar,
                                                   codiceAreaSepa varchar,
                                                   codiceAreaExtraSepa varchar,
                                                   accreditoCodeCB varchar,
                                                   accreditoCodeREG varchar,
                                                   tipoPagamCompensa varchar,
 												   accreditoTipoId INTEGER,
                                                   accreditoGruppoCode varchar,
                                                   importoOrd       numeric,
                                                   pagamentoGFB     boolean,
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
isCompensa boolean:=false;
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
 -- codiceAreaExtraSepa letto in param

-- raise notice 'ordinativoId=% ',ordinativoId;
-- raise notice 'codicePaese=% ',codicePaese;
-- raise notice 'codiceItalia=% ',codiceItalia;
-- raise notice 'codiceAreaSepa=% ',codiceAreaSepa;
-- raise notice 'codiceAreaExtraSepa=% ',codiceAreaExtraSepa;

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

 if isProvvisori = false then
  checkDati:=null;
  strMessaggio:='Verifica ordinativo compensazione.';
  select 1 into checkDati
  from siac_r_ordinativo rOrd, siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo,
       siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato,
       siac_t_ordinativo_ts ts, siac_t_ordinativo_ts_det det, siac_d_ordinativo_ts_det_tipo tipod,
       siac_d_relaz_tipo tiporel
  where rord.ord_id_da=ordinativoId
  and   ord.ord_id=rord.ord_id_a
  and   tipo.ord_tipo_id=ord.ord_tipo_id
  and   tipo.ord_tipo_code='I'
  and   rstato.ord_id=ord.ord_id
  and   stato.ord_stato_id=rstato.ord_stato_id
 -- and   stato.ord_stato_code!='A' 29.07.2019 Sofia siac-6971 - la validita sulla siac_r_ordinativo deve guidare nn lo stato
  and   ts.ord_id=ord.ord_id
  and   det.ord_ts_id=ts.ord_ts_id
  and   tipod.ord_ts_det_tipo_id=det.ord_ts_det_tipo_id
  and   tipod.ord_ts_det_tipo_code='A'
  and   tiporel.relaz_tipo_id=rOrd.relaz_tipo_id
  and   rord.data_cancellazione is null
  and   rord.validita_fine is null
  and   ord.data_cancellazione is null
  and   ord.validita_fine is null
  and   rstato.data_cancellazione is null
  and   rstato.validita_fine is null
  and   ts.data_cancellazione is null
  and   ts.validita_fine is null
  and   det.data_cancellazione is null
  and   det.validita_fine is null
--  group by ord.ord_id
  group by rord.ord_id_da -- 20.12.2017 Sofia jira siac-5665
  having coalesce(sum(det.ord_ts_det_importo),0)=importoOrd
  limit 1;

  if checkDati is not null then
    strMessaggio:='Lettura tipo pamento compensazione.';
  	select oil.accredito_tipo_oil_code ,oil.accredito_tipo_oil_desc
           into accreditoCodePag,accreditoDescPag
    from siac_d_accredito_tipo_oil oil
    where oil.ente_proprietario_id=enteProprietarioId
    and   oil.accredito_tipo_oil_desc=tipoPagamCompensa
    and   oil.data_cancellazione is null
    and   oil.validita_fine is null;
    if accreditoCodePag is not null  then
    	isCompensa:=true;
    end if;
  end if;
 end if;

 if isProvvisori = false and isCompensa=false then
 	if codicePaese='' or codicePaese is null then
     -- 14.02.2018 Sofia siac-5874
     checkDati:=null;
     strMessaggio:='Lettura gruppo tipo pagamento '||accreditoCodeCB||'.';
	 select 1 into checkDati
     from siac_d_accredito_gruppo gruppo, siac_d_accredito_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.accredito_tipo_code=accreditoCodeCB
     and   gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id
     and   gruppo.accredito_gruppo_code=accreditoGruppoCode
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

 	 -- se il codice paese='' or codicepaese is null
 	 -- cerco il gruppo da accredito_tipo_id
	 -- se e' CB allora forzo paese=' '
--     if accreditoGruppoCode=accreditoCodeCB then
     -- 14.02.2018 Sofia siac-5874
     if checkDati is not null then
     	codicePaese=' '; -- forzato per cercare CB extrasepa
     end if;

    end if;
 end if;


 if isProvvisori=false and  isCompensa=false and
    codicePaese is not null and codicePaese!=codiceItalia then
    strMessaggio:='Lettura tipo pagamento ordinativo [siac_t_sepa].';
    checkDati:=null; -- 14.02.2018 Sofia siac-5874
 	select distinct 1 into checkDati
    from siac_t_sepa sepa
    where sepa.sepa_iso_code=codicePaese
    and   sepa.ente_proprietario_id=enteProprietarioId
    and   sepa.data_cancellazione is null
 	and   date_trunc('day',dataElaborazione)>=date_trunc('day',sepa.validita_inizio)
 	and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(sepa.validita_fine,dataElaborazione));

    if checkDati is not null then
    	isSepa:=true;
    end if;
 end if;

 if isProvvisori=true THEN
 	-- lettura tabella di decodifica REG ( valore presente in param )
    accreditoCodeTes:=accreditoCodeREG;
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
 -- raise notice 'isSepa=% ',isSepa;


 if isProvvisori=false and isCompensa=false  and
    codicePaese is not  null and  codicePaese!=codiceItalia  then
    accreditoCodeTes:=accreditoCodeCB;
 	if isSepa=true then
	 	-- lettura tabella di decodifica con CB ( valore presente in param), oil_area=SEPA
    	codAreaSepa:=codiceAreaSepa;
    else
	 	-- lettura tabella di decodifica con CB ( valore presente in param), oil_area=EXTRASEPA
	    codAreaSepa:=codiceAreaExtraSepa;
        isAllegatoCartaceo  :=true; -- bonifico estero extra-sepa forzato a true
    end if;

 end if;

 if  isCompensa=false  then

  if isProvvisori=false and -- 13.12.2017 Sofia siac-5654
     (accreditoCodeTes is null or  pagamentoGFB = true ) then
     accreditoTipoOilId:=accreditoTipoId;
     if pagamentoGFB=true then
    	codAreaSepa:=null;
     end if;
  else -- caso ordinativo a copertura==con provvisori  di cassa collegati

     -- 08.05.2018 Sofia siac-6137 - leggo l'accredito tipo di ordinativo che sia del tipo REGOLARIZZAZIONE - se si lo uso
     -- diversamente imposto REGOLARIZZAZIONE COME PRIMA
     -- lettura di accredito_tipo_id per lettura in accredito_tipo
	 strMessaggio:='Lettura tipo pagamento ordinativo [siac_d_accredito_tipo] accredito_tipo_desc like '||accreditoCodeTes||'.';


     select tipo.accredito_tipo_id into accreditoTipoOilId
 	 from siac_d_accredito_tipo tipo
	 where tipo.accredito_tipo_id=accreditoTipoId
     and   tipo.accredito_tipo_desc like accreditoCodeTes||'%'
	 and   tipo.data_cancellazione is null
	 and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
	 and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

     -- 08.05.2018 Sofia siac-6137
     if accreditoTipoOilId is null then
        -- lettura di accredito_tipo_id per lettura in accredito_tipo x REG
		strMessaggio:='Lettura tipo pagamento ordinativo [siac_d_accredito_tipo] accredito_tipo_code='||accreditoCodeTes||'.';
		select tipo.accredito_tipo_id into accreditoTipoOilId
		from siac_d_accredito_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
	    and   tipo.accredito_tipo_code=accreditoCodeTes
		and   tipo.data_cancellazione is null
		and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
		and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
     end if;

	 if accreditoTipoOilId is null then
 		RAISE EXCEPTION ' Accredito tipo non trovato.';
	 end if;
  end if;

 end if;

 if  isCompensa=false  then

  -- lettura di accredito_tipo_id per lettura in accredito_tipo_oil
  strMessaggio:='Lettura tipo pagamento ordinativo [siac_d_accredito_tipo_oil].';
  select oil.accredito_tipo_oil_code,oil.accredito_tipo_oil_desc into accreditoCodePag,accreditoDescPag
  from siac_d_accredito_tipo_oil oil, siac_r_accredito_tipo_oil raccre
  where raccre.accredito_tipo_id=accreditoTipoOilId
  and   raccre.data_cancellazione is null
  and   raccre.validita_fine is null
  and   oil.accredito_tipo_oil_id=raccre.accredito_tipo_oil_id
  and   coalesce(oil.accredito_tipo_oil_area,'IT')=coalesce(codAreaSepa,'IT')
  and   oil.data_cancellazione is null
  and   date_trunc('day',dataElaborazione)>=date_trunc('day',oil.validita_inizio)
  and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(oil.validita_fine,dataElaborazione));
 end if;



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