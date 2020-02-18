/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_function_using_function_owner_all (
)
RETURNS TABLE (
  function_user_name varchar,
  function_user_proowner oid,
  function_user_rolname name,
  function_used_name varchar,
  function_used_proowner oid,
  function_used_rolname name
) AS
$body$
DECLARE
fnc_rec record;
fnc_rec2 record;
DEF_NULL    constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
contatore integer;
contatore_interno integer;
function_used_name_1 varchar;
function_used_name_2 varchar;

/*campi tabella destinazione*/

BEGIN

contatore:=0;
contatore_interno:=0;

for fnc_rec in 
SELECT distinct proname,proowner FROM pg_proc 
order by 1  
loop
contatore:=contatore+1;
function_used_name:=fnc_rec.proname;
function_used_proowner:=fnc_rec.proowner;
--raise notice 'contatore: %', contatore;  
--raise notice 'funzione usata: %', function_used_name;  

function_used_name_1:='%'||function_used_name||' %';
function_used_name_2:='%'||function_used_name||'(%';


for 
fnc_rec2 in 
SELECT distinct proname,proowner
FROM 
pg_proc 
WHERE 
prosrc like function_used_name_1
or prosrc like function_used_name_2
         --  and  proname ~* schema_name
         /*   --  prosrc ~* function_used_name
        --    and proname !~~ '^function_used_name$'
	    --and proname <> function_used_name*/
order by 1
loop
contatore_interno:=contatore_interno+1;
--raise notice 'contatore: %', contatore ||'.'||contatore_interno; 
function_user_name:=fnc_rec2.proname;
function_user_proowner:=fnc_rec2.proowner;


if   function_used_name=function_user_name THEN
function_user_name:=null;
else 
--raise notice 'funzione usante: %', function_user_name; 
--raise notice 'la funzione % usa la funzione %', function_user_name,function_used_name;  
end if;

select rolname into function_used_rolname from pg_authid where oid=function_used_proowner;
select rolname into function_user_rolname from pg_authid where oid=function_user_proowner;
       
return next; 



 function_user_name:=null;
end loop;


  
return next;
function_used_name:=null;
end loop;





raise notice 'fine OK';
exception
    when no_data_found THEN
        raise notice 'non trovato' ;
        return;
    when others  THEN
        RTN_MESSAGGIO:='altro errore';
         RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;