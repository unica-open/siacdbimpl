/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_converti_data (
  p_data_in varchar
)
RETURNS varchar AS
$body$
declare
result character varying :='';
data_input character varying :='';
anno character varying :='';
mese character varying :='';
giorno character varying :='';
begin

  data_input := p_data_in;
if data_input is not null and  char_length(data_input)=10 then

	anno := substring(data_input from 7 for 4);
	mese := substring(data_input from 4 for 2);
	giorno := substring(data_input from 1 for 2);

	raise notice 'anno %', anno ;
	raise notice 'mese %', mese ;
	raise notice 'giorno %', giorno ;

	result := anno ||'-'|| mese ||'-'|| giorno;

	raise notice 'result %', result;
else
    result := null;
end if;

RETURN result;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;