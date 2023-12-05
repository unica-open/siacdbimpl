/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_function_using_function_owner (
rolname_user_in varchar,
rolname_used_in varchar
)
RETURNS TABLE (
  function_user_name varchar,
  function_user_proowner oid,
  function_user_rolname pg_authid.rolname%type,
  function_used_name varchar,
  function_used_proowner oid,
  function_used_rolname pg_authid.rolname%type 
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

-- da invocare cosi:
-- select * from fnc_siac_bko_function_using_function_owner('siac','siac') where function_user_name is not null

BEGIN

contatore:=0;
contatore_interno:=0;

for fnc_rec in 
SELECT distinct p.proname, p.proowner,a.rolname
 FROM pg_proc p,
pg_authid a where 
a.oid=p.proowner and 
a.rolname=rolname_used_in::name
order by 1  
loop
contatore:=contatore+1;
function_used_name:=fnc_rec.proname;
function_used_proowner:=fnc_rec.proowner;
function_used_rolname:=fnc_rec.rolname;
--raise notice 'contatore: %', contatore;  
--raise notice 'funzione usata: %', function_used_name;  

function_used_name_1:='%'||function_used_name||' %';
function_used_name_2:='%'||function_used_name||'(%';


for 
fnc_rec2 in
SELECT distinct p.proname, p.proowner, a.rolname  
FROM pg_proc p,pg_authid a 
where a.oid=p.proowner and a.rolname=rolname_user_in::name
and (p.prosrc like function_used_name_1
or prosrc like function_used_name_2)
order by 1
/*SELECT distinct p.proname, p.proowner
FROM 
pg_proc p
WHERE 
prosrc like function_used_name_1
or prosrc like function_used_name_2
--  and  proname ~* schema_name
--  prosrc ~* function_used_name
--    and proname !~~ '^function_used_name$'
--and proname <> function_used_name
order by 1*/
loop
contatore_interno:=contatore_interno+1;
--raise notice 'contatore: %', contatore ||'.'||contatore_interno; 
function_user_name:=fnc_rec2.proname;
function_user_proowner:=fnc_rec2.proowner;
function_user_rolname:=fnc_rec2.rolname;


/*if   function_used_name=function_user_name THEN
function_user_name:=null;
else 
--raise notice 'funzione usante: %', function_user_name; 
--raise notice 'la funzione % usa la funzione %', function_user_name,function_used_name;  
end if;
*/
/*select rolname into function_used_rolname from pg_authid where oid=function_used_proowner;
select rolname into function_user_rolname from pg_authid where oid=function_user_proowner;*/
       
return next; 



function_user_name:=null;
function_user_proowner:=null;
function_user_rolname:=null;
end loop;


  
return next;
function_used_name:=null;
function_used_proowner:=null;
function_used_rolname:=null;
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