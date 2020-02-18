/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


CREATE OR REPLACE FUNCTION fnc_mif_tipo_incasso_splus( ordinativoId integer,
  											           ordinativoImporto numeric,
                                                       ritRelCode varchar,
                                                       splitRelCode varchar,
                                                       subRelCode varchar,
                                                       tipoOnere varchar,
 												       tipoIncassoCodeId INTEGER,
                                                       tipoIncassoCompensazione varchar,
                                                       tipoIncassoRegolarizza varchar,
                                                       tipoIncassoCassa  varchar,
                                                       dataElaborazione timestamp,
                                                       dataFineVal timestamp,
                                                       enteProprietarioId integer)
RETURNS varchar AS
$body$
DECLARE

strMessaggio varchar(1500):=null;

isProvvisori boolean :=false;
checkDati integer:=null;
tipoIncasso varchar(150):=null;
tipoIncassoToRel varchar(150):=null;

tipoOnereOk integer:=null;

ordId integer:=null;
relazTipoCode varchar:=null;
ordImporto numeric:=null;
tipoOnereCode1 varchar:=null;
tipoOnereCode2 varchar:=null;
tipoOnereCode3 varchar:=null;
BEGIN


 strMessaggio:='Lettura tipoIncasso per ordinativoId='||ordinativoId::varchar||'.';

 strMessaggio:=strMessaggio||' Lettura classificatore [siac_r_ordinativo_class].';
 select c.classif_desc into tipoIncasso
 from siac_r_ordinativo_class r, siac_t_class c
 where r.ord_id=OrdinativoId
 and   c.classif_id=r.classif_id
 and   c.classif_tipo_id=tipoIncassoCodeId
 and   r.data_cancellazione is null
 and   r.validita_fine is null
 and   c.data_cancellazione is null
 order  by r.ord_classif_id limit 1;

 strMessaggio:='Lettura tipoIncasso per ordinativoId='||ordinativoId::varchar||' .Verifica provvisori di cassa.';

 -- se Ordinativo a copertura
 select distinct 1 into checkDati
 from siac_r_ordinativo_prov_cassa rprov
 where rprov.ord_id=OrdinativoId
 and   rprov.data_cancellazione is null
 and   rprov.validita_fine is null;

 if checkDati is not null then
    -- se esiste collegamento con siac_d_accretipo_tipo_oil
    -- tipoIncassoToRel --> accredito_tipo_oil_desc_incasso
    -- altrimenti REGOLARIZZAZIONE
    if tipoIncasso is not null then
     strMessaggio:='Lettura tipoIncasso per ordinativoId='||ordinativoId::varchar||'.Ordinativo a copertura.Verifica tipo incasso collegato [siac_r_accredito_tipo_plus].';

 	 select r.accredito_tipo_oil_desc_incasso into tipoIncassoToRel
     from siac_r_accredito_tipo_plus r ,siac_d_accredito_tipo_oil oil
     where oil.ente_proprietario_id=enteProprietarioId
     and   oil.accredito_tipo_oil_desc=tipoIncasso
     and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
     and   r.data_cancellazione is null
     and   r.validita_fine is null
     and   oil.data_cancellazione is null
     and   oil.validita_fine is null
     limit 1;
    end if;

    if tipoIncassoToRel is null then
    	tipoIncassoToRel:=tipoIncassoRegolarizza;
    end if;

 end if;

 -- se non a copertura
 if tipoIncassoToRel is null then
  -- se Ordinativo collegato ad ordinativo di spesa, di pari importo
  -- COMPENSAZIONE
  strMessaggio:='Lettura tipoIncasso per ordinativoId='||ordinativoId::varchar||'.Ordinativo non a copertura.'||
                'Verifica ordinativo di pagamento collegato.';

  select ord.ord_id , tiporel.relaz_tipo_code, coalesce(sum(det.ord_ts_det_importo),0)
         into ordId, relazTipoCode, ordImporto
  from siac_r_ordinativo rOrd, siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo,
       siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato,
       siac_t_ordinativo_ts ts, siac_t_ordinativo_ts_det det, siac_d_ordinativo_ts_det_tipo tipod,
       siac_d_relaz_tipo tiporel
  where rord.ord_id_a=ordinativoId
  and   ord.ord_id=rord.ord_id_da
  and   tipo.ord_tipo_id=ord.ord_tipo_id
  and   tipo.ord_tipo_code='P'
  and   rstato.ord_id=ord.ord_id
  and   stato.ord_stato_id=rstato.ord_stato_id
  and   stato.ord_stato_code!='A'
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
  group by ord.ord_id,tiporel.relaz_tipo_code;

  if ordId is not null and
    coalesce(ordImporto,0)!=0 and coalesce(ordImporto,0)=ordinativoImporto
    then
 	tipoIncassoToRel:=tipoIncassoCompensazione;
  --  raise notice 'Importo uguale tipoIncassoToRel=%',tipoIncassoToRel;
  end if;
 end if;

 -- se non a copertura e non compensazione
 -- se ordinativo di tipo ritenuta
 -- quindi collegato ad ordinativo di spesa
 -- con relazione RIT_ORD
 -- e ordinativo di spesa collegato a documenti
 -- con oneri IRPEF,INPS, IRPEG
 -- COMPENSAZIONE
 if tipoIncassoToRel is null and
    ordId is not null and
    relazTipoCode in
    (ritRelCode,splitRelCode,subRelCode) then

	tipoIncassoToRel:=tipoIncassoCompensazione;
    raise notice 'relazTipoCode=% tipoIncassoToRel=%',relazTipoCode,tipoIncassoToRel;

	if relazTIpoCode=ritRelCode then
     strMessaggio:='Lettura tipoIncasso per ordinativoId='||ordinativoId::varchar||'.Ordinativo non a copertura.'||
                   'Verifica ordinativo di pagamento collegato con ritenuta.';
   --  raise notice 'strMessaggio=% ',strMessaggio;
   --  raise notice 'tipoOnere=% ordId=%',tipoOnere,ordId;
     tipoOnereCode1:=trim (both ' ' from split_part(tipoOnere,',',1));
     tipoOnereCode2:=trim (both ' ' from split_part(tipoOnere,',',2));
     tipoOnereCode3:=trim (both ' ' from split_part(tipoOnere,',',3));
    -- raise notice 'tipoOnereCode1=% ordId=%',tipoOnereCode1,ordId;
   --  raise notice 'tipoOnereCode2=% ordId=%',tipoOnereCode2,ordId;
    -- raise notice 'tipoOnereCode3=% ordId=%',tipoOnereCode3,ordId;

	 select distinct 1 into tipoOnereOk
	 from siac_d_onere onere, siac_d_onere_tipo tipo,
          siac_t_ordinativo_ts ordts, siac_r_doc_onere  rdoc, siac_t_subdoc doc, siac_r_subdoc_ordinativo_ts ts
	 where onere.ente_proprietario_id=enteProprietarioId
     and   tipo.onere_tipo_id=onere.onere_tipo_id
	 and   tipo.onere_tipo_code in (tipoOnereCode1,tipoOnereCode2,tipoOnereCode3)
	 and   ordts.ord_id=ordId
	 and   ts.ord_ts_id=ordts.ord_ts_id
	 and   doc.subdoc_id=ts.subdoc_id
	 and   rdoc.doc_id=doc.doc_id
	 and   rdoc.onere_id=onere.onere_id
  	 and   onere.data_cancellazione is null
     and   onere.validita_fine is null
	 and   ordts.data_cancellazione is null
	 and   ordts.validita_fine is null
	 and   ts.data_cancellazione is null
	 and   ts.validita_fine is null
	 and   doc.data_cancellazione is null
 	 and   doc.validita_fine is null
	 and   rdoc.data_cancellazione is null
	 and   rdoc.validita_fine is null;

     raise notice 'tipoOnereOk=%',tipoOnereOk;
     if tipoOnereOk is  null then
    	tipoIncassoToRel:=null;
     end if;
    end if;


 end if;

 -- se nessuna delle condizion sopra allora vale il tipo presente sul classificatore
 if tipoIncassoToRel is null then
 	tipoIncassoToRel:=tipoIncasso;
 end if;
 -- se nessun valore --> allora CASSA
 if tipoIncassoToRel is null then
 	tipoIncassoToRel:=tipoIncassoCassa;
 end if;

 raise notice 'tipoIncassoToRel=% ',tipoIncassoToRel;



 return tipoIncassoToRel;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',coalesce(strMessaggio,'')||' '||coalesce(substring(upper(SQLERRM) from 1 for 1000),'');
        return tipoIncassoToRel;
    when TOO_MANY_ROWS THEN
        RAISE EXCEPTION '% Diverse righe lette.',coalesce(strMessaggio,'');
        return tipoIncassoToRel;
   when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',coalesce(strMessaggio,'');
        return tipoIncassoToRel;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',coalesce(strMessaggio,''),SQLSTATE,substring(SQLERRM from 1 for 1000);
        return tipoIncassoToRel;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;