/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_mif_ordinativo_splus_get_mese
(
 dataToMese  varchar
)
RETURNS varchar AS
$body$
DECLARE

dMese integer;

mifFlussoElabMeseArr varchar[];

strMese varchar;

begin

strMese:='Gennaio';
mifFlussoElabMeseArr[1]:=strMese;
strMese:='Febbraio';
mifFlussoElabMeseArr[2]:=strMese;
strMese:='Marzo';
mifFlussoElabMeseArr[3]:=strMese;
strMese:='Aprile';
mifFlussoElabMeseArr[4]:=strMese;
strMese:='Maggio';
mifFlussoElabMeseArr[5]:=strMese;
strMese:='Giugno';
mifFlussoElabMeseArr[6]:=strMese;
strMese:='Luglio';
mifFlussoElabMeseArr[7]:=strMese;
strMese:='Agosto';
mifFlussoElabMeseArr[8]:=strMese;
strMese:='Settembre';
mifFlussoElabMeseArr[9]:=strMese;
strMese:='Ottobre';
mifFlussoElabMeseArr[10]:=strMese;
strMese:='Novembre';
mifFlussoElabMeseArr[11]:=strMese;
strMese:='Dicembre';
mifFlussoElabMeseArr[12]:=strMese;

dMese:=substring(dataToMese from 6 for 2)::integer;

if dMese between 1 and 12 then
	 strMese:=mifFlussoElabMeseArr[dMese];
else strMese:=null;
end if;

return strMese;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;