/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION fnc_mif_ordinativo_onere( ordinativoId integer,
 												     codiceTribTipoId INTEGER,
                                                     estraiCausali boolean,
                                                     enteProprietarioId integer,
                                                     dataElaborazione timestamp,
                                                     dataFineVal timestamp,
                                                     out listaOneri varchar,
                                                     out listaCausali varchar)
RETURNS record AS
$body$
DECLARE

strMessaggio varchar(1500):=null;

listaValoriOneri varchar(500):=null;
listaValoriCau  varchar(500):=null;
onereRec record;
causaliRec record;

bEndOneri boolean:=false;
bEndCausali boolean:=false;

BEGIN


 strMessaggio:='Lettura ordindativo onere-causali.';
 listaOneri:=null;
 listaCausali:=null;

 for onereRec in
 (select distinct onere.onere_code,onere.onere_id
  from siac_d_onere onere,siac_t_ordinativo_ts ordts,siac_r_doc_onere  rdoc, siac_t_subdoc doc, siac_r_subdoc_ordinativo_ts ts
  where onere.ente_proprietario_id=enteProprietarioId
  and   onere.onere_tipo_id= codiceTribTipoId
  and   onere.data_cancellazione is null
  and   date_trunc('day',dataElaborazione)>=date_trunc('day',onere.validita_inizio)
--  and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(onere.validita_fine,dataFineVal)) 19.01.2017
  and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(onere.validita_fine,dataElaborazione))
  and   ordts.ord_id=ordinativoId
  and   ordts.data_cancellazione is null
  and   ordts.validita_fine is null
  and   ts.ord_ts_id=ordts.ord_ts_id
  and   ts.data_cancellazione is null
  and   ts.validita_fine is null
  and   doc.subdoc_id=ts.subdoc_id
  and   doc.data_cancellazione is null
  and   doc.validita_fine is null
  and   rdoc.doc_id=doc.doc_id
  and   rdoc.onere_id=onere.onere_id
  and   rdoc.data_cancellazione is null
  and   rdoc.validita_fine is null
 )
 loop
	if estraiCausali=true and bEndCausali=false then
    	for causaliRec in
        (select distinct cau.caus_code
         from siac_r_onere_causale rcau, siac_d_causale cau
         where rcau.onere_id=onereRec.onere_id
         and   rcau.data_cancellazione is null
         and   rcau.validita_fine is null
         and   cau.caus_id=rcau.caus_id
         and   cau.data_cancellazione is null
         and   date_trunc('day',dataElaborazione)>=date_trunc('day',cau.validita_inizio)
--  	     and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(cau.validita_fine,dataFineVal))) 19.01.2017
  	     and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(cau.validita_fine,dataElaborazione)))
        loop
        	if length(listaValoriCau)+length(causaliRec.caus_code)>200 then
    			bEndCausali:=true;
                exit;
	   		end if;
            if listaValoriCau is not null then
		        listaValoriCau:=listaValoriCau||' '||causaliRec.caus_code;
            else
                listaValoriCau:=causaliRec.caus_code;
            end if;
        end loop;
    end if;

 	if length(listaValoriOneri)+length(onereRec.onere_code)>200 then
    		bEndOneri:=true;
    else
    	if listaValoriOneri is not null then
		    listaValoriOneri:=listaValoriOneri||' '|| onereRec.onere_code;
        else
	        listaValoriOneri:=onereRec.onere_code;
        end if;
    end if;

    if bEndCausali=true and bEndOneri=true then
    	exit;
    end if;
    if estraiCausali=false and bEndOneri=true then
    	exit;
    end if;

 end loop;


 listaOneri:=listaValoriOneri;
 listaCausali:=listaValoriCau;

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