/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop function if exists siac.fnc_siac_impegnatoresiduo_effettivo_attuale_ug ( id_in integer);
CREATE OR REPLACE FUNCTION siac.fnc_siac_impegnatoresiduo_effettivo_attuale_ug ( id_in integer)
RETURNS numeric  AS
$body$
DECLARE



importoImpegnato numeric:=0;
strMessaggio varchar(1500):=null;

BEGIN
    
    strMessaggio:='Calcolo totale impegnato residuo effettivo iniziale elem_id='||id_in|| '.';
    importoImpegnato:=fnc_siac_impegnatoresiduo_effettivo_ug ( id_in, 'A');
		if importoImpegnato is null then importoImpegnato:=0; end if;

	raise notice 'importoImpegnato=%',importoImpegnato;
	return importoImpegnato;


exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
		return importoImpegnato;
	when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
		return importoImpegnato;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
		return importoImpegnato;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;



ALTER FUNCTION siac.fnc_siac_impegnatoresiduo_effettivo_attuale_ug (id_in integer) OWNER TO siac;
 
