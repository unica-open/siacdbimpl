/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_td_crea_abi_cab (
  abi_code_in varchar,
  abi_desc_in varchar,
  cab_code_in varchar,
  cab_desc_in varchar,
  cab_citta_in varchar,
  cab_indirizzo_in varchar,
  cab_cap_in varchar,
  cab_provincia_in  varchar,
  numero_incident varchar
)
RETURNS TABLE (
  v_messaggiorisultato text
) AS
$body$
DECLARE
abi_id_new siac_t_abi.abi_id%type;
cab_id_test siac_t_cab.cab_id%type;
v_messaggiorisultato_tmp text;
sql_to_run text;
c_enti record;
c_cab record;
BEGIN
v_messaggiorisultato :='';
v_messaggiorisultato_tmp:='';

 abi_desc_in:=replace( abi_desc_in,'''','''''');
 cab_desc_in:=replace( cab_desc_in,'''','''''');
 cab_citta_in:=replace( cab_citta_in,'''','''''');
 cab_indirizzo_in:=replace( cab_indirizzo_in,'''','''''');
 cab_provincia_in:=replace( cab_provincia_in,'''','''''');
 
 if abi_code_in is null then 
	    v_messaggiorisultato:='Il codice ABI non può essere nullo';
        RAISE EXCEPTION 'Il codice ABI non può essere nullo';
elsif abi_desc_in is null then 
	    v_messaggiorisultato:='La descrizione del codice ABI non può essere nulla';
        RAISE EXCEPTION 'La descrizione del codice ABI non può essere nulla';        
 elsif cab_code_in is null then
 v_messaggiorisultato:='Il codice CAB non può essere nullo';
 		RAISE EXCEPTION 'Il codice CAB non può essere nullo'; 
 elsif cab_desc_in is null then 
	    v_messaggiorisultato:='La descrizione del codice CAB non può essere nulla';
        RAISE EXCEPTION 'La descrizione del codice CAB non può essere nulla';   
elsif numero_incident is null then 
	    v_messaggiorisultato:='Il numero incident non può essere nullo';
        RAISE EXCEPTION 'Il numero incident non può essere nullo';                
end if;

cab_citta_in:=COALESCE(cab_citta_in,'');
cab_indirizzo_in:=COALESCE(cab_indirizzo_in,'');
cab_cap_in:=COALESCE(cab_cap_in,'');
cab_provincia_in:=COALESCE(cab_provincia_in,'');







for c_enti in 
select a.ente_proprietario_id from siac_t_ente_proprietario a where a.ente_proprietario_id 
not in (7,8) 
order by 1 loop


INSERT INTO 
  siac.siac_t_abi
(
  abi_code,
  abi_desc,
  validita_inizio,
  nazione_id,
  ente_proprietario_id,
  login_operazione
)
select 
abi_code_in,abi_desc_in, now(), a.nazione_id,a.ente_proprietario_id,
numero_incident from siac_t_nazione a where 
a.ente_proprietario_id=c_enti.ente_proprietario_id and 
upper(a.nazione_code)='ITALIA'
and not exists (select 1 from siac_t_abi z where z.ente_proprietario_id=a.ente_proprietario_id
and z.abi_code=abi_code_in and z.abi_desc=abi_desc_in
)
returning abi_id into abi_id_new;

if abi_id_new is null then 
v_messaggiorisultato:= 'Codice Abi già presente';
end if;


select a.cab_id into cab_id_test  from siac_t_cab a, siac_t_abi b
 where b.abi_id=a.abi_id and a.ente_proprietario_id=c_enti.ente_proprietario_id and
 a.cab_code=cab_code_in and b.abi_code=abi_code_in;
 
-- raise notice 'ente % cab_id_test %', c_enti.ente_proprietario_id ,cab_id_test;

if cab_id_test is null then 

--inserimento cab
sql_to_run:=
'INSERT INTO siac_t_cab_'||c_enti.ente_proprietario_id::varchar||' (
cab_abi,cab_code,cab_citta,cab_indirizzo,cab_cap,cab_desc,cab_provincia,
  abi_id,validita_inizio,nazione_id,ente_proprietario_id,login_operazione)
select '''||abi_code_in||''', '''||cab_code_in
||''', upper('''||cab_citta_in||'''), upper('''||cab_indirizzo_in
||'''), '''||cab_cap_in||''', upper('''||cab_desc_in||'''), upper('''||cab_provincia_in||
'''), a.abi_id, now(), b.nazione_id, a.ente_proprietario_id'||', '''||numero_incident||''' 
from siac_t_abi a,siac_t_nazione b where a.ente_proprietario_id='||c_enti.ente_proprietario_id||' and 
a.abi_code='''||abi_code_in||''' 
and b.ente_proprietario_id=a.ente_proprietario_id
and upper(b.nazione_desc) =''ITALIA'' and not exists (select 1 from siac_t_cab z where 
z.ente_proprietario_id=a.ente_proprietario_id and 
z.cab_code='''||cab_code_in||''' and z.cab_abi='''||abi_code_in||''')
;';

--raise notice '%', sql_to_run;

execute sql_to_run;
v_messaggiorisultato:= v_messaggiorisultato||' - creato CAB ' ||cab_code_in||' per l''ente '||c_enti.ente_proprietario_id::varchar;
else 
v_messaggiorisultato:= 'Codice cab già presente per l''ente '||c_enti.ente_proprietario_id::varchar;
end if;

return next;
v_messaggiorisultato:='';

end loop;



exception
    when RAISE_EXCEPTION THEN
    v_messaggiorisultato:=v_messaggiorisultato|| ' - ' ||substring(upper(SQLERRM) from 1 for 2500);
          return next;
	when others  THEN
	v_messaggiorisultato:=v_messaggiorisultato|| ' others - ' ||substring(upper(SQLERRM) from 1 for 2500);
        return next;
    

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;