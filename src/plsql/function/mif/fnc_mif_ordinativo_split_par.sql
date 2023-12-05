/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_mif_ordinativo_split_par ( param varchar)
RETURNS TABLE
(
	elemPar varchar
 ) AS
$body$
DECLARE

strMessaggio varchar(1500):=null;
elemVal varchar(100):=null;
elemNum integer :=1;
BEGIN
	strMessaggio:='Split param.';
    loop
        elemPar:=null;
        elemVal:=null;
    	elemVal:=split_part(param,'|',elemNum);
--        raise notice 'elemVal %',elemVal;
        exit when elemVal is null or elemVal ='';
    	elemPar:=elemVal;
        return next;
        elemNum:=elemNum+1;
    end loop;

    return;
exception
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;