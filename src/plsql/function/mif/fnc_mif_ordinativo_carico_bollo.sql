/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
REATE OR REPLACE FUNCTION fnc_mif_ordinativo_carico_bollo( codiceBollo varchar,
														    paramCaricoBollo varchar)
RETURNS varchar AS
$body$
DECLARE

strMessaggio varchar(1500):=null;


SEPARATORE  CONSTANT VARCHAR:='|';



valBolloCarico varchar(100):=null;

countBolloCarico integer:=1;

codiceBolloCarico varchar(50):=null;
numeroValori integer:=0;

BEGIN


 strMessaggio:='Verifica ordinativo carico bollo.';


 if paramCaricoBollo is not null then
    numeroValori:=trim (both ' ' from split_part(paramCaricoBollo,SEPARATORE,1))::integer;
    if numeroValori>0 then
     loop
	    codiceBolloCarico:=trim (both ' ' from split_part(paramCaricoBollo,SEPARATORE,(countBolloCarico*2)));
        if codiceBolloCarico is not null then
        	 if codiceBolloCarico=codiceBollo THEN
             	valBolloCarico:=trim (both ' ' from split_part(paramCaricoBollo,SEPARATORE,(countBolloCarico*2)+1));
             end if;
        else countBolloCarico:=(countBolloCarico*2)+1;
        end if;
        countBolloCarico:=countBolloCarico+1;
      exit when (countBolloCarico>numeroValori or valBolloCarico is not null);
     end loop;
    end if;
 end if;


 return valBolloCarico;


exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',coalesce(strMessaggio,'')||' '||coalesce(substring(upper(SQLERRM) from 1 for 1000),'');
        return valBolloCarico;
    when TOO_MANY_ROWS THEN
        RAISE EXCEPTION '% Diverse righe lette.',coalesce(strMessaggio,'');
        return valBolloCarico;
   when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',coalesce(strMessaggio,'');
        return valBolloCarico;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',coalesce(strMessaggio,''),SQLSTATE,substring(SQLERRM from 1 for 1000);
        return valBolloCarico;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;