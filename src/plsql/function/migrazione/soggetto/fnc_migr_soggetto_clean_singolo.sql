/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_soggetto_clean_singolo ()
RETURNS integer AS
$body$
DECLARE
idmin integer:=50554;

rec record;
BEGIN


loop
    raise notice 'idMin=%',idmin;
	select * into rec
    from fnc_migr_soggetto_clean(2,'migr_soggetti',idmin,idmin,'S');

    idmin=idmin+1;
    exit when idmin>51553;
end loop;

return 0;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;