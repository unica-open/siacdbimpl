/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_mif_ordinativo_a_copertura (
  ordinativoid integer,
  accreditotipoid integer,
  elencomdpcopertura varchar,
  dataelaborazione timestamp,
  datafineval timestamp,
  enteproprietarioid integer
)
RETURNS boolean AS
$body$
DECLARE

strMessaggio varchar(1500):=null;


SEPARATORE  CONSTANT VARCHAR:='|';

flagCopertura boolean:=false;
numeroMDPCopertura integer:=0;
countMDPCopertura integer:=1;
isACopertura integer:=null;
MDPCopertura varchar(50):=null;


BEGIN

 -- flag_copertura=true se
 -- 1. accreditoTipoId in una di quelle passate in elencoMDPCopertura
 -- 2. or esistono provvisori di cassa collegati a ordinativo
 -- 3. or esistono carte contabili collegate

 strMessaggio:='Verifica ordinativo a copertura.';

 -- 1.
 if elencoMDPCopertura is not null then
 	strMessaggio:='Verifica ordinativo a copertura per accredito tipi '||elencoMDPCopertura||'.';
	numeroMDPCopertura:=trim (both ' ' from split_part(elencoMDPCopertura,SEPARATORE,1))::integer;
    if numeroMDPCopertura>0 then
     loop
     	MDPCopertura:=trim (both ' ' from split_part(elencoMDPCopertura,SEPARATORE,countMDPCopertura+1));
        if MDPCopertura is not null then
             select 1 into isACopertura -- 12.05.2017 Sofia
             from siac_d_accredito_tipo tipo--, siac_d_accredito_gruppo gruppo
             where tipo.accredito_tipo_id=accreditoTipoId
             and   tipo.accredito_tipo_code=MDPCopertura
             and   tipo.data_cancellazione is null
	       	 and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
 --		     and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal)) 19.01.2017
 		     and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));
--             and   gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id
--             and   gruppo.accredito_gruppo_code=MDPCopertura
--             and   gruppo.data_cancellazione is null
--         	 and   date_trunc('day',dataElaborazione)>=date_trunc('day',gruppo.validita_inizio)
---- 		  	 and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(gruppo.validita_fine,dataFineVal)); 19.01.2017
-- 		  	 and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(gruppo.validita_fine,dataElaborazione));
        else countMDPCopertura:=numeroMDPCopertura+1;
        end if;
        countMDPCopertura:=countMDPCopertura+1;
      exit when (countMDPCopertura>numeroMDPCopertura or isACopertura is not null);
     end loop;
    end if;

    if  isACopertura is not null then
	    flagCopertura:=true;
    end if;
 end if;

 -- 2.
 if flagCopertura=false then
	strMessaggio:='Verifica ordinativo a copertura per esistenza provvisori di cassa collegati.';
 	select distinct 1 into isACopertura
    from siac_r_ordinativo_prov_cassa prov
    where prov.ord_id=ordinativoId
    and   prov.data_cancellazione is null
    and   prov.validita_fine is null;
    if  isACopertura is not null then
	    flagCopertura:=true;
    end if;
 end if;

 -- 3.
 if flagCopertura=false then
  strMessaggio:='Verifica ordinativo a copertura per esistenza carte contabili collegate.';

  select distinct ordts.ord_ts_id into isACopertura
  from  siac_t_ordinativo_ts ordts, siac_r_subdoc_ordinativo_ts subdoc,siac_r_cartacont_det_subdoc carta
  where ordts.ord_id=ordinativoId
    and ordts.data_cancellazione is null
    and ordts.validita_fine is null
    and subdoc.ord_ts_id=ordts.ord_ts_id
    and subdoc.data_cancellazione is null
    and subdoc.validita_fine is null
    and carta.subdoc_id=subdoc.subdoc_id
    and carta.data_cancellazione is null
    and carta.validita_fine is null;

	if  isACopertura is not null then
	    flagCopertura:=true;
    end if;

 end if;


 return flagCopertura;


exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',coalesce(strMessaggio,'')||' '||coalesce(substring(upper(SQLERRM) from 1 for 1000),'');
        return flagCopertura;
    when TOO_MANY_ROWS THEN
        RAISE EXCEPTION '% Diverse righe lette.',coalesce(strMessaggio,'');
        return flagCopertura;
   when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',coalesce(strMessaggio,'');
        return flagCopertura;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',coalesce(strMessaggio,''),SQLSTATE,substring(SQLERRM from 1 for 1000);
        return flagCopertura;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;