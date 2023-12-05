/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_mif_ordinativo_esenzione_bollo( codiceBollo varchar,
														       paramEsenzione varchar)
RETURNS boolean AS
$body$
DECLARE

strMessaggio varchar(1500):=null;


SEPARATORE  CONSTANT VARCHAR:='|';

isEsente boolean:=false;


countEsenzione integer:=1;

codiceEsente varchar(50):=null;
numeroEsenzione integer:=0;

BEGIN


 strMessaggio:='Verifica ordinativo bollo esente.';


 if paramEsenzione is not null then
    numeroEsenzione:=trim (both ' ' from split_part(paramEsenzione,SEPARATORE,1))::integer;
    if numeroEsenzione>0 then
     loop
	    codiceEsente:=trim (both ' ' from split_part(paramEsenzione,SEPARATORE,countEsenzione+1));
        if codiceEsente is not null then
        	 if codiceEsente=codiceBollo THEN
             	isEsente=true;
             end if;
        else countEsenzione:=numeroEsenzione+1;
        end if;
        countEsenzione:=countEsenzione+1;
      exit when (countEsenzione>numeroEsenzione or isEsente=true);
     end loop;
    end if;
 end if;


 return isEsente;


exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',coalesce(strMessaggio,'')||' '||coalesce(substring(upper(SQLERRM) from 1 for 1000),'');
        return isEsente;
    when TOO_MANY_ROWS THEN
        RAISE EXCEPTION '% Diverse righe lette.',coalesce(strMessaggio,'');
        return isEsente;
   when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',coalesce(strMessaggio,'');
        return isEsente;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',coalesce(strMessaggio,''),SQLSTATE,substring(SQLERRM from 1 for 1000);
        return isEsente;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;