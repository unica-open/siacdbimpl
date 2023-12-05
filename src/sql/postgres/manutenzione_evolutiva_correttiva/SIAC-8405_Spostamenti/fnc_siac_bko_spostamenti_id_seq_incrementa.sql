/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

drop FUNCTION  if exists siac.fnc_siac_bko_spostamenti_id_seq_incrementa();

CREATE OR REPLACE FUNCTION  siac.fnc_siac_bko_spostamenti_id_seq_incrementa()
RETURNS integer AS
$body$
DECLARE


begin
	
	
return nextval('siac_bko_spostamenti_id_seq'::regclass);

exception
    when others  THEN
        raise notice 'Errore DB % %',SQLSTATE,  substring(upper(SQLERRM) from 1 for 500);
        return -1;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

alter function siac.fnc_siac_bko_spostamenti_id_seq_incrementa()  OWNER to siac;