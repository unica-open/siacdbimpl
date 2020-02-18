/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_td_crea_pdce_conto_enti (
  famiglia_in varchar,
  pdce_conto_code_in varchar,
  pdce_conto_desc_in varchar,
  codificabilancio_in varchar,
  inizio_validita varchar,
  numero_incident varchar
)
RETURNS TABLE (
  v_messaggiorisultato text
) AS
$body$
DECLARE
pdce_conto_id_out siac_t_pdce_conto.pdce_conto_id%type;
c_enti record;
v_messaggiorisultato_tmp text;
BEGIN
v_messaggiorisultato :='';
v_messaggiorisultato_tmp:='';

pdce_conto_desc_in:= replace(pdce_conto_desc_in,'''','''''');

for c_enti in 
select a.ente_proprietario_id from siac_t_ente_proprietario a where a.ente_proprietario_id 
not in (7,8) order by 1 loop

--inserimento siac_t_pdce_conto lascio padre a null per fare dopo update


INSERT INTO siac.siac_t_pdce_conto(
pdce_conto_code,
pdce_conto_desc,
livello, 
ordine, 
pdce_fam_tree_id,
pdce_ct_tipo_id, 
validita_inizio, 
ente_proprietario_id, 
login_operazione,login_creazione,ambito_id)
select pdce_conto_code_in,pdce_conto_desc_in,
 array_length(string_to_array(pdce_conto_code_in, '.'), 1) livello,
pdce_conto_code_in ordine, b.pdce_fam_tree_id,c.pdce_ct_tipo_id,to_timestamp(inizio_validita,'dd/mm/yyyy'),--to_timestamp('01/01/2017','dd/mm/yyyy'),
b.ente_proprietario_id,numero_incident,numero_incident,d.ambito_id
 from --tmp_insert_pdce_conto a,
 siac_t_pdce_fam_tree b,siac_d_pdce_conto_tipo c, 
 siac_d_ambito d
 where b.pdce_fam_code=famiglia_in
 and c.ente_proprietario_id=b.ente_proprietario_id
 and c.pdce_ct_tipo_code='GE'
 and d.ente_proprietario_id=b.ente_proprietario_id
 and d.ambito_code in ('AMBITO_FIN')--,'AMBITO_GSA')
 and b.ambito_id=d.ambito_id
 and b.validita_fine is null
 and not exists (select 1 from siac_t_pdce_conto z where z.pdce_conto_code=pdce_conto_code_in
 and z.ente_proprietario_id=b.ente_proprietario_id
 and z.pdce_fam_tree_id=b.pdce_fam_tree_id
 and z.ambito_id=d.ambito_id
 and z.validita_fine is null
  )
  and c.ente_proprietario_id=c_enti.ente_proprietario_id
  returning 
  pdce_conto_id into pdce_conto_id_out
;

--select a.pdce_conto_id into pdce_conto_id_out from siac_t_pdce_conto a where a.login_operazione=numero_incident;
 

if pdce_conto_id_out is not null then
update siac_t_pdce_conto set pdce_conto_id_padre=subquery.pdce_conto_id,
login_operazione=login_operazione||' - updpadre_id='||subquery.pdce_conto_id::varchar
 from 
(select 
a.pdce_conto_id,
a.pdce_conto_code,
a.ente_proprietario_id,b.pdce_fam_tree_id,c.ambito_id from
siac_t_pdce_conto a, siac_t_pdce_fam_tree b, siac_d_ambito c
where b.pdce_fam_tree_id=a.pdce_fam_tree_id
and c.ambito_id=a.ambito_id
and b.ambito_id=c.ambito_id
) as subquery
where 
siac_t_pdce_conto.pdce_fam_tree_id=subquery.pdce_fam_tree_id and 
array_to_string(array_append(string_to_array(subquery.pdce_conto_code, '.'), ((
string_to_array(siac_t_pdce_conto.pdce_conto_code, '.')) [ array_upper(string_to_array(
siac_t_pdce_conto.pdce_conto_code, '.'), 1) ])), '.') = siac_t_pdce_conto.pdce_conto_code
and siac_t_pdce_conto.login_operazione=numero_incident
and subquery.ambito_id=siac_t_pdce_conto.ambito_id
and siac_t_pdce_conto.pdce_conto_id_padre is null
and siac_t_pdce_conto.ente_proprietario_id=c_enti.ente_proprietario_id
;
 


--inserimento attributo pdce_conto_attivo, conto di legge per tutti S

INSERT INTO 
  siac.siac_r_pdce_conto_attr
(	
  pdce_conto_id,
  attr_id,
  "boolean",
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
 select c.pdce_conto_id,
a.attr_id, 'S', to_timestamp(inizio_validita,'dd/mm/yyyy'),c.ente_proprietario_id, numero_incident
 from siac_t_pdce_conto c, siac_t_attr a--,tmp_insert_pdce_conto d
where a.ente_proprietario_id=c.ente_proprietario_id 
and c.login_creazione =numero_incident
and 
pdce_conto_code_in=c.pdce_conto_code and 
a.attr_code
 in ('pdce_conto_attivo','pdce_conto_di_legge')
 and not exists (select 1 from siac_r_pdce_conto_attr b where 
b.attr_id=a.attr_id and b.pdce_conto_id=c.pdce_conto_id
and b.data_cancellazione is null
and b.validita_fine is null
)
and c.ente_proprietario_id=c_enti.ente_proprietario_id
;



--inserimento attributo conto foglia

INSERT INTO 
  siac.siac_r_pdce_conto_attr
(
  pdce_conto_id,
  attr_id,
  "boolean",
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
 select c.pdce_conto_id,
a.attr_id, 'S', to_timestamp(inizio_validita,'dd/mm/yyyy'),c.ente_proprietario_id, numero_incident
 from siac_t_pdce_conto c, siac_t_attr a, siac_t_pdce_fam_tree f, --tmp_insert_pdce_conto g,
 siac_d_ambito h
where a.ente_proprietario_id=c.ente_proprietario_id
and f.pdce_fam_tree_id=c.pdce_fam_tree_id
and c.login_creazione =numero_incident
and  pdce_conto_code_in=c.pdce_conto_code
and f.pdce_fam_code in ('AP','PP','OP')
and c.livello=7
and h.ambito_id=c.ambito_id
and h.ambito_code='AMBITO_FIN'
and  a.attr_code
 in ('pdce_conto_foglia') and not exists ( 
  select 1 from siac_r_pdce_conto_attr b, siac_t_pdce_conto b2 where b.attr_id=a.attr_id and b.pdce_conto_id=c.pdce_conto_id 
  and b2.pdce_conto_id=b.pdce_conto_id
  and b2.pdce_conto_id_padre=c.pdce_conto_id
  )
 and not exists ( 
  select 1 from siac_r_pdce_conto_attr z where
  z.attr_id=a.attr_id and z.pdce_conto_id=c.pdce_conto_id 
  and z.data_cancellazione is null
  and z.validita_fine is null
  )
  and c.ente_proprietario_id=c_enti.ente_proprietario_id
  ;


INSERT INTO siac.siac_r_pdce_conto_attr
(
  pdce_conto_id,
  attr_id,
  "boolean",
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
 select 
  c.pdce_conto_id,
a.attr_id, 'S', to_timestamp(inizio_validita,'dd/mm/yyyy'),c.ente_proprietario_id, numero_incident
 from siac_t_pdce_conto c, siac_t_attr a, siac_t_pdce_fam_tree f, --tmp_insert_pdce_conto g,
 siac_d_ambito h
where a.ente_proprietario_id=c.ente_proprietario_id
and f.pdce_fam_tree_id=c.pdce_fam_tree_id
and c.login_creazione =numero_incident
and   pdce_conto_code_in=c.pdce_conto_code
and f.pdce_fam_code in ('CE','RE')
and c.livello=6
and h.ambito_id=c.ambito_id
and h.ambito_code='AMBITO_FIN'
and  a.attr_code
 in ('pdce_conto_foglia') and not exists ( 
  select 1 from siac_r_pdce_conto_attr b, siac_t_pdce_conto b2 where b.attr_id=a.attr_id 
  and b.pdce_conto_id=c.pdce_conto_id 
  and b2.pdce_conto_id=b.pdce_conto_id
  and b2.pdce_conto_id_padre=c.pdce_conto_id
  )
and not exists ( 
  select 1 from siac_r_pdce_conto_attr z where
  z.attr_id=a.attr_id and z.pdce_conto_id=c.pdce_conto_id 
  and z.data_cancellazione is null
  and z.validita_fine is null
  ) 
and c.ente_proprietario_id=c_enti.ente_proprietario_id  
;


--inserimento mapping con classificatori albero
INSERT INTO 
  siac.siac_r_pdce_conto_class 
(
  pdce_conto_id,
  classif_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select tb.pdce_conto_id,tb.classif_id_new,tb.validita_ini, 
tb.ente_proprietario_id,tb.login_oper from (
select 
d.pdce_conto_id, 
c.classif_id classif_id_new,
to_timestamp(inizio_validita,'dd/mm/yyyy') validita_ini,
d.ente_proprietario_id, 
numero_incident login_oper
 from --tmp_insert_pdce_conto a, 
 siac_v_dwh_codifiche_econpatr c,siac_t_pdce_conto d, 
 siac_d_pdce_fam e,siac_d_ambito f ,siac_t_pdce_fam_tree g
where 
d.login_creazione=numero_incident and 
famiglia_in=e.pdce_fam_code
and pdce_conto_code_in=d.pdce_conto_code
and c.ente_proprietario_id=d.ente_proprietario_id
and c.codice_codifica_albero=codificabilancio_in
and e.data_cancellazione is null
and g.pdce_fam_id=e.pdce_fam_id
and d.pdce_fam_tree_id=g.pdce_fam_tree_id
and now() BETWEEN e.validita_inizio and coalesce(e.validita_fine, now())
and f.ambito_id=e.ambito_id and f.ambito_code='AMBITO_FIN'
and g.data_cancellazione is null
and now() BETWEEN g.validita_inizio and coalesce(g.validita_fine, now())
and case when famiglia_in in ('CE','RE') then 'conto economico (codice di bilancio)' 
end = c.tipo_codifica
and codificabilancio_in is not null and trim(codificabilancio_in)<>''
union 
select
d.pdce_conto_id, 
c.classif_id classif_id_new,
to_timestamp(inizio_validita,'dd/mm/yyyy'),
d.ente_proprietario_id, 
numero_incident
 from --tmp_insert_pdce_conto a, 
 siac_v_dwh_codifiche_econpatr c,siac_t_pdce_conto d, siac_d_pdce_fam e,siac_d_ambito f ,siac_t_pdce_fam_tree g
where 
d.login_creazione=numero_incident and 
famiglia_in=e.pdce_fam_code
and pdce_conto_code_in=d.pdce_conto_code
and c.ente_proprietario_id=d.ente_proprietario_id
and c.codice_codifica_albero=substring (codificabilancio_in from 3)
and e.data_cancellazione is null
and g.pdce_fam_id=e.pdce_fam_id
and d.pdce_fam_tree_id=g.pdce_fam_tree_id
and now() BETWEEN e.validita_inizio and coalesce(e.validita_fine, now())
and f.ambito_id=e.ambito_id and f.ambito_code='AMBITO_FIN'
and g.data_cancellazione is null
and now() BETWEEN g.validita_inizio and coalesce(g.validita_fine, now())
and famiglia_in in ('AP','PP')
and case when substring(codificabilancio_in from 1 for 1) = 'A' then 'stato patrimoniale attivo (codice di bilancio)' 
end = c.tipo_codifica
and  codificabilancio_in is not null and trim(codificabilancio_in)<>''
union
select 
d.pdce_conto_id, 
c.classif_id classif_id_new,
to_timestamp(inizio_validita,'dd/mm/yyyy'),
d.ente_proprietario_id, 
numero_incident
 from --tmp_insert_pdce_conto a,
 siac_v_dwh_codifiche_econpatr c,siac_t_pdce_conto d, siac_d_pdce_fam e,siac_d_ambito f ,siac_t_pdce_fam_tree g
where 
d.login_creazione=numero_incident and 
famiglia_in=e.pdce_fam_code
and pdce_conto_code_in=d.pdce_conto_code
and c.ente_proprietario_id=d.ente_proprietario_id
and c.codice_codifica_albero=substring (codificabilancio_in from 3)
and e.data_cancellazione is null
and g.pdce_fam_id=e.pdce_fam_id
and d.pdce_fam_tree_id=g.pdce_fam_tree_id
and now() BETWEEN e.validita_inizio and coalesce(e.validita_fine, now())
and f.ambito_id=e.ambito_id and f.ambito_code='AMBITO_FIN'
and g.data_cancellazione is null
and now() BETWEEN g.validita_inizio and coalesce(g.validita_fine, now())
and famiglia_in in ('AP','PP')
and case when substring(codificabilancio_in from 1 for 1) = 'P' then 'stato patrimoniale passivo (codice di bilancio)' 
end = c.tipo_codifica
and  codificabilancio_in is not null and trim(codificabilancio_in)<>''
--and d.login_operazione like '%admininserimentodel20180117-CR953%'
) as tb
where 
 not exists (select 1 from siac_r_pdce_conto_class z where z.classif_id=tb.classif_id_new
and z.pdce_conto_id=tb.pdce_conto_id and z.validita_fine is null)
and tb.ente_proprietario_id=c_enti.ente_proprietario_id
;

/*if pdce_conto_id_out is not null then 
v_messaggiorisultato:= 'Eseguita creazione del pdce_conto '||pdce_conto_code_in;
end if;*/




end if;

if pdce_conto_id_out is not null THEN

with pdce_new as (select 
a.ente_proprietario_id,
a.pdce_conto_id,a.pdce_conto_code,a.pdce_conto_id_padre
from siac_t_pdce_conto a where a.login_creazione=numero_incident and a.pdce_conto_id=pdce_conto_id_out)
,
attivo as (select 
b.attr_code,
a.pdce_conto_id,a."boolean" valore from siac_r_pdce_conto_attr a,siac_t_attr b
where b.attr_id=a.attr_id
and a.login_operazione=numero_incident
and b.attr_code='pdce_conto_attivo'
)
,
legge as (select b.attr_code,
a.pdce_conto_id,a."boolean" valore from siac_r_pdce_conto_attr a,siac_t_attr b
where b.attr_id=a.attr_id
and a.login_operazione=numero_incident
and b.attr_code='pdce_conto_di_legge'
)
,
foglia as (select b.attr_code,
a.pdce_conto_id,a."boolean" valore from siac_r_pdce_conto_attr a,siac_t_attr b
where b.attr_id=a.attr_id
and a.login_operazione=numero_incident
and b.attr_code='pdce_conto_foglia'
),
pdc as (select a.pdce_conto_id,c.ordine from siac_r_pdce_conto_class a, siac_t_class b,siac_r_class_fam_tree c
where a.login_operazione=numero_incident and b.classif_id=a.classif_id
and c.classif_id=b.classif_id
)
select 
'creato per l''ente ' ||pdce_new.ente_proprietario_id::text || ' il pdce_conto '|| pdce_new.pdce_conto_code
|| ' con pdce_conto_id='||pdce_new.pdce_conto_id::text 
|| ' con c.pdce_conto_id_padre='||pdce_new.pdce_conto_id_padre::text
||' conto_attivo='||coalesce(attivo.valore, 'N')
||' conto_di_legge='||coalesce(legge.valore, 'N')
||' conto_foglia='||coalesce(foglia.valore, 'N')
|| ' codice bilancio='|| coalesce(pdc.ordine, 'Non collegato')
|| ' '
into v_messaggiorisultato_tmp
 From pdce_new
left join attivo on pdce_new.pdce_conto_id=attivo.pdce_conto_id
left join legge on pdce_new.pdce_conto_id=legge.pdce_conto_id
left join foglia on pdce_new.pdce_conto_id=foglia.pdce_conto_id
left join pdc on pdce_new.pdce_conto_id=pdc.pdce_conto_id;

else

v_messaggiorisultato_tmp:= 'conto non creato per l''ente ' ||c_enti.ente_proprietario_id::text || ' ';

end if;

pdce_conto_id_out:=null;
v_messaggiorisultato:=v_messaggiorisultato_tmp;
return next;
v_messaggiorisultato:=null;
v_messaggiorisultato_tmp:=null;
end loop;

--return v_messaggiorisultato;

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
