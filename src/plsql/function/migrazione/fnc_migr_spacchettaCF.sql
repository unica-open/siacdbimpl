/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--DROP FUNCTION fnc_migr_spacchettaCF(text, dataNascita out text, comuneNascita out text,sesso out text );
CREATE OR REPLACE FUNCTION fnc_migr_spacchettaCF(varchar, dataNascita out varchar, comuneNascita out varchar,sesso out varchar
												, messaggioRisultato out varchar,codiceRisultato out integer ) RETURNS record
AS $$
DECLARE
	x integer;
	split1 varchar:='';
    split2 varchar:='';
    split3 varchar:='';
    split4 varchar:='';
    gg varchar:='';
    mm varchar:='';
    aaaa varchar:='';
    aaSystem VARCHAR(2):='';
    pattern varchar := '^([a-zA-Z]{6})([0-9]{2})([abcdehlmprstABCDEHLMPRST]{1})([0-9]{2})([a-zA-Z]{1}[0-9]{3})([a-zA-Z]{1})$';
    regexOk varchar :='';
    strMessaggio varchar :='';

BEGIN
	messaggioRisultato := 'Recupero info anagrafiche da CF.';
    codiceRisultato := 0;
	if $1 is null or $1 = '' then
    	RAISE EXCEPTION 'input null or empty [ % ]', quote_nullable($1) ;
    end if;

    begin
		strMessaggio :='Pattern Matching.';
	    select * into strict regexOk from regexp_matches($1,pattern);
	exception
    	when NO_DATA_FOUND then
        	-- il soggetto verrà comunque inserito nella siac_t_soggetto e sarà anche inserito un record nella tabella migr_soggetto_scarto
        	RAISE EXCEPTION 'Il codice fiscale non è formalmente valido.';
        when others then
        	RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
	end;

    split1 := substring($1 from 7 for 2); -- ANNO
    split2 := substring($1 from 9 for 1); -- MESE
    split3 := substring($1 from 10 for 2); -- GIORNO
    split4 := substring($1 from 12 for 4); -- BELFIORE

	select to_char (now(),'YY') into aaSystem;
    if aaSystem > split1 then  aaaa := '20'; else aaaa := '19'; end if;
	aaaa := aaaa||split1;
	mm := case upper(split2)
    				  when 'A' then '01'
    				  when 'B' then '02'
                      when 'C' then '03'
                      when 'D' then '04'
                      when 'E' then '05'
                      when 'H' then '06'
                      when 'L' then '07'
                      when 'M' then '08'
                      when 'P' then '09'
                      when 'R' then '10'
                      when 'S' then '11'
                      when 'T' then '12' end;

    x = split3::integer;
    if x-40 > 0 then
    	sesso := 'F';
        gg :=  (x-40)::varchar;
    else
    	sesso := 'M';
        gg :=  split3;
	end if;
	
    dataNascita := aaaa||'-'||mm||'-'||gg;

    -- DAVIDE - 08.01.016 - aggiunto controllo data di nascita
	--if (mm = '') or
	--   ((mm in ('04','06', '09', '11')) and (gg::integer > 30) ) or
	--   ((mm in ('01','03', '05', '07', '08', '10', '12')) and (gg::integer > 31) ) or
	--   ((mm = '02') and (gg::integer > 29)) then
    --	RAISE EXCEPTION 'born date invalid [ % ]', quote_nullable($1) ;
    -- end if;

    begin
    
        perform dataNascita::date;
     
    exception when others then
        RAISE EXCEPTION 'born date invalid [ % ]', quote_nullable($1);
    end;
	-- DAVIDE - 08.01.016 - Fine

    comuneNascita := split4;
    messaggioRisultato := messaggioRisultato||'Ok.';

EXCEPTION
    when RAISE_EXCEPTION THEN
    	raise notice '% ERRORE : %',messaggioRisultato,substring(upper(SQLERRM) from 1 for 800);
        messaggioRisultato:=messaggioRisultato||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 200) ;
        codiceRisultato:=-1;
        return;
    WHEN others THEN
        messaggioRisultato:='ERRORE DB :'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 200) ;
        codiceRisultato:=-1;
        return;
END;
$$ LANGUAGE plpgsql IMMUTABLE;