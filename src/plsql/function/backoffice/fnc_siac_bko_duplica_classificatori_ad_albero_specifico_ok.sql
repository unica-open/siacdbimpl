/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_duplica_classificatori_ad_albero_specifico_ok (
  ente_prop_origine_id integer,
  anno_origine varchar,
  ente_prop_dest_id integer,
  anno_dest varchar,
  famiglia_classificatori_code varchar
)
RETURNS TABLE (
  tabella varchar
) AS
$body$
DECLARE
rec record;
rec2 record;
contatore integer;
contatore2 integer;
stringone varchar;  
stringone2 varchar; 
tabella_nome varchar;
tabella_nome2 varchar;
tabella_campo varchar;
tabella_campo2 varchar;
tabella_campo_val varchar;
tabella_campo_val2 varchar;
elenco_campi varchar;
r record;
elenco_campi2 varchar;
primary_key_campo varchar;
primary_key_campo2 varchar;
primary_key_seq varchar;
primary_key_seq2 varchar;
sql_primary_key_upd13 varchar;
sql_primary_key_upd14 varchar;
sql_primary_key_upd15 varchar;
login_operaz varchar;

table_name_pk varchar;
name_pk varchar;
field_pk VARCHAR;
field_code VARCHAR;
cf varchar;
maxclass integer;
minclass integer;
delta integer;
inizio_anno_origine varchar;
inizio_anno_dest varchar;
fine_anno_dest varchar;
fine_anno_origine varchar;
inizio_anno_origine_t timestamp;
inizio_anno_dest_t timestamp;
fine_anno_dest_t timestamp;
fine_anno_origine_t timestamp;
rec4 record;
classif_fam_tree_id_a_new integer;
classif_id_a_new integer;
classif_fam_tree_id_b_new integer;
classif_id_b_new integer;
 validita_ini timestamp;
 ciclo integer;
BEGIN
ciclo:=0;
login_operaz:='fnc_siac_bko_duplica_classificatori_ad_albero_specifico_ok';

inizio_anno_origine:='01/01/'||anno_origine;
inizio_anno_dest:='01/01/'||anno_dest;
fine_anno_dest:='31/12/'||anno_dest;
fine_anno_origine:='31/12/'||anno_origine;

inizio_anno_origine_t:=to_timestamp(inizio_anno_origine,'dd/mm/yyyy');
inizio_anno_dest_t:=to_timestamp(inizio_anno_dest,'dd/mm/yyyy');
fine_anno_dest_t:=to_timestamp(fine_anno_dest,'dd/mm/yyyy');
fine_anno_origine_t:=to_timestamp(fine_anno_origine,'dd/mm/yyyy');

 validita_ini := to_timestamp(inizio_anno_origine,'dd/mm/yyyy');

sql_primary_key_upd13:='SELECT SETVAL(''siac_t_class_classif_id_seq'', COALESCE(MAX(classif_id),0)+1,false ) FROM siac_t_class';
EXECUTE sql_primary_key_upd13;



raise notice 'prima di rec: %', clock_timestamp()::varchar;

--per ogni testata
for rec in 
select 
tc.classif_fam_tree_id,
tc.class_fam_code,
tc.class_fam_desc,
df2.classif_fam_id,
tc.validita_inizio,
tc.validita_fine,
df2.ente_proprietario_id,
tc.data_creazione,
tc.data_modifica,
tc.data_cancellazione,
tc.login_operazione
from siac_t_class_fam_tree tc,siac_d_class_fam df, siac_d_class_fam df2
where tc.ente_proprietario_id=ente_prop_origine_id
and tc.data_cancellazione is null
and tc.classif_fam_id=df.classif_fam_id
and df.classif_fam_code=famiglia_classificatori_code
and df.classif_fam_code=df2.classif_fam_code
and df2.ente_proprietario_id=ente_prop_dest_id
order by 1
loop
ciclo:=ciclo+1;
--trovo DELTA = (MAX+1) - MIN

sql_primary_key_upd13:='SELECT SETVAL(''siac_t_class_classif_id_seq'', COALESCE(MAX(classif_id),0)+1,false ) FROM siac_t_class';
EXECUTE sql_primary_key_upd13;

select max(classif_id) into maxclass 
from siac_t_class;

select min (classif_id) into minclass 
from siac_t_class
where classif_id in
(
select classif_id from siac_r_class_fam_tree a,siac_t_class_fam_tree b,siac_d_class_fam c where 
a.classif_fam_tree_id=b.classif_fam_tree_id AND
b.classif_fam_tree_id = rec.classif_fam_tree_id and
b.ente_proprietario_id=ente_prop_origine_id
and b.data_cancellazione is null
and c.classif_fam_id=b.classif_fam_id
);

delta:=(maxclass-minclass)+1;

/*raise notice 'maxclass:%', maxclass;
raise notice 'minclass:%', minclass;
raise notice 'delta:%', delta;
*/

raise notice 'rec prima di insert siac_t_class_fam_tree ciclo : % - %', ciclo, clock_timestamp()::varchar;

INSERT INTO 
siac.siac_t_class_fam_tree
(
class_fam_code,
class_fam_desc,
classif_fam_id,
validita_inizio,
validita_fine,
ente_proprietario_id,
login_operazione
)
select
rec.class_fam_code,
rec.class_fam_desc,
rec.classif_fam_id,
rec.validita_inizio,
rec.validita_fine,
rec.ente_proprietario_id,
login_operaz
from siac_t_class_fam_tree z where
now() BETWEEN z.validita_inizio and coalesce(z.validita_fine,now())
 and not exists (select 1 from siac_t_class_fam_tree z2
where z2.class_fam_code=rec.class_fam_code)
;

raise notice 'rec dopo insert siac_t_class_fam_tree ciclo : % - %', ciclo, clock_timestamp()::varchar;

raise notice 'rec prima di insert siac_t_class : % - %', ciclo, clock_timestamp()::varchar;


INSERT INTO 
siac.siac_t_class
(
classif_id,
classif_code,
classif_desc,
classif_tipo_id,
validita_inizio,
validita_fine,
ente_proprietario_id,
login_operazione
)
select distinct
cla.classif_id+delta,
cla.classif_code,
cla.classif_desc,
cti2.classif_tipo_id,
cla.validita_inizio,
cla.validita_fine,
ente_prop_dest_id,
login_operaz
from siac_t_class cla, siac_d_class_tipo cti,siac_d_class_tipo cti2,
siac_r_class_fam_tree gg 
where 
cti.classif_tipo_id=cla.classif_tipo_id and 
cti.classif_tipo_code=cti2.classif_tipo_code and
cla.ente_proprietario_id=ente_prop_origine_id and
cti2.ente_proprietario_id=ente_prop_dest_id and 
cla.data_cancellazione is null and
cti.data_cancellazione is null and
cti2.data_cancellazione is null and  
gg.classif_id=cla.classif_id and gg.classif_fam_tree_id=rec.classif_fam_tree_id
/*cla.classif_id in (
select classif_id from siac_r_class_fam_tree gg 
where gg.classif_id=cla.classif_id and 
gg.classif_fam_tree_id=rec.classif_fam_tree_id
)
*/;   

raise notice 'rec dopo di insert siac_t_class ciclo : % - %', ciclo, clock_timestamp()::varchar;


sql_primary_key_upd13:='SELECT SETVAL(''siac_t_class_classif_id_seq'', COALESCE(MAX(classif_id),0)+1,false ) FROM siac_t_class';
EXECUTE sql_primary_key_upd13;


raise notice 'rec prima di insert siac_r_class_fam_tree ciclo : % - %', ciclo, clock_timestamp()::varchar;


INSERT INTO 
  siac.siac_r_class_fam_tree
(
  classif_fam_tree_id,
  classif_id,
  classif_id_padre,
  ordine,
  livello,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select 
tc2.classif_fam_tree_id,
rcl1.classif_id+delta,
rcl1.classif_id_padre+delta,
rcl1.ordine,
rcl1.livello,
rcl1.validita_inizio,
rcl1.validita_fine,
ente_prop_dest_id,
login_operaz
from siac_r_class_fam_tree rcl1, siac_t_class_fam_tree tc1,siac_t_class_fam_tree tc2
where 
rcl1.classif_fam_tree_id=tc1.classif_fam_tree_id
and tc1.class_fam_code=tc2.class_fam_code
and rcl1.ente_proprietario_id=ente_prop_origine_id
and tc2.ente_proprietario_id=ente_prop_dest_id
and rcl1.data_cancellazione is null
and tc1.data_cancellazione is null
and tc2.data_cancellazione is null
and rcl1.classif_fam_tree_id=rec.classif_fam_tree_id
;

sql_primary_key_upd14:='SELECT SETVAL(''siac_r_class_fam_tree_classif_classif_fam_tree_id_seq'', COALESCE(MAX(classif_classif_fam_tree_id),0)+1,false ) FROM siac_r_class_fam_tree';
EXECUTE sql_primary_key_upd14;
raise notice 'rec dopo di insert siac_r_class_fam_tree ciclo : % - %', ciclo, clock_timestamp()::varchar;


RETURN NEXT;
end loop;

raise notice 'dopo rec: %', clock_timestamp()::varchar;

sql_primary_key_upd14:='SELECT SETVAL(''siac_r_class_classif_classif_id_seq'', COALESCE(MAX(classif_classif_id),0)+1,false ) FROM siac_r_class';
EXECUTE sql_primary_key_upd14;

raise notice 'prima di rec4: %', clock_timestamp()::varchar;
for rec4 in 
 select 
rfta.classif_fam_tree_id classif_fam_tree_id_a,
rftb.classif_fam_tree_id classif_fam_tree_id_b,
cll.validita_inizio validita_inizio_coppia_old, 
cll.validita_fine validita_fine_coppia_old,
cll.ente_proprietario_id ente_proprietario_id,
cl1.classif_id classif_id_a,
cl1.classif_code classif_code_a,
cl1.classif_desc classif_desc_a, 
t1.classif_tipo_code classif_tipo_code_a,
cl1.validita_inizio validita_inizio_a, 
cl1.validita_fine validita_fine_a,
cl2.classif_id classif_id_b,
cl2.classif_code classif_code_b,
cl2.classif_desc classif_desc_b, 
t2.classif_tipo_code classif_tipo_code_b,
cl2.validita_inizio validita_inizio_b, 
cl2.validita_fine validita_fine_b
from siac_r_class cll, siac_r_class_fam_tree rfta,siac_r_class_fam_tree rftb,
siac_t_class cl1, siac_d_class_tipo t1,
siac_t_class cl2, siac_d_class_tipo t2,
siac_t_class_fam_tree fta,
siac_t_class_fam_tree ftb,
siac_d_class_fam dfa,
siac_d_class_fam dfb
where cll.classif_a_id=rfta.classif_id
and cll.classif_b_id=rftb.classif_id
and cll.ente_proprietario_id=ente_prop_origine_id
and cll.data_cancellazione is null
and 
cll.classif_a_id=cl1.classif_id
and 
cll.classif_b_id=cl2.classif_id
and t1.classif_tipo_id=cl1.classif_tipo_id
and t2.classif_tipo_id=cl2.classif_tipo_id
and cl1.data_cancellazione is null
and cl2.data_cancellazione is NULL
and t1.data_cancellazione is null
and t2.data_cancellazione is null
and cll.data_cancellazione is null
and rfta.classif_fam_tree_id=fta.classif_fam_tree_id
and rftb.classif_fam_tree_id=ftb.classif_fam_tree_id
and dfa.classif_fam_id=fta.classif_fam_id
and dfb.classif_fam_id=ftb.classif_fam_id
and dfa.classif_fam_desc=famiglia_classificatori_code
and dfb.classif_fam_desc=famiglia_classificatori_code
/*and validita_ini between cll.validita_inizio and COALESCE(cll.validita_fine, validita_ini)
and validita_ini between cl1.validita_inizio and COALESCE(cl1.validita_fine, validita_ini)
and validita_ini between cl2.validita_inizio and COALESCE(cl2.validita_fine, validita_ini)*/
and not COALESCE(cll.validita_fine, validita_ini)<validita_ini
and not COALESCE(cl1.validita_fine, validita_ini)<validita_ini
and not COALESCE(cl2.validita_fine, validita_ini)<validita_ini
order by 6,12
  loop
  
  --albero A NEW
  
  
  
  select fanew.classif_fam_tree_id into classif_fam_tree_id_a_new
  from 
  siac_t_class_fam_tree fanew, siac_t_class_fam_tree fanold
  where 
  fanold.classif_fam_tree_id=rec4.classif_fam_tree_id_a and
  fanew.ente_proprietario_id = ente_prop_dest_id and
  fanew.class_fam_code=fanold.class_fam_code  and
  fanew.class_fam_desc=fanold.class_fam_desc and
  fanew.validita_inizio=fanold.validita_inizio 
  and coalesce(fanew.validita_fine, to_timestamp('01/01/3000','dd/mm/yyyy'))=coalesce(fanold.validita_fine, to_timestamp('01/01/3000','dd/mm/yyyy'));

  
  --corrispondenza CLASSIFICATORE A
  select classif_id into classif_id_a_new
  from siac_t_class clnew where clnew.ente_proprietario_id = ente_prop_dest_id
  and clnew.classif_code=rec4.classif_code_a
  and clnew.classif_desc=rec4.classif_desc_a
  and clnew.validita_inizio=rec4.validita_inizio_a
  and coalesce(clnew.validita_fine, to_timestamp('01/01/3000','dd/mm/yyyy'))=coalesce(rec4.validita_fine_a, to_timestamp('01/01/3000','dd/mm/yyyy'))
  and exists (select 1 from  siac_r_class_fam_tree rtnew where rtnew.classif_fam_tree_id=classif_fam_tree_id_a_new and rtnew.classif_id=clnew.classif_id);



  --albero B NEW
  
  select fanew.classif_fam_tree_id into classif_fam_tree_id_b_new
  from 
  siac_t_class_fam_tree fanew, siac_t_class_fam_tree fanold
  where 
  fanold.classif_fam_tree_id=rec4.classif_fam_tree_id_b and
  fanew.ente_proprietario_id = ente_prop_dest_id and
  fanew.class_fam_code=fanold.class_fam_code  and
  fanew.class_fam_desc=fanold.class_fam_desc and
  fanew.validita_inizio=fanold.validita_inizio 
  and coalesce(fanew.validita_fine, to_timestamp('01/01/3000','dd/mm/yyyy'))=coalesce(fanold.validita_fine, to_timestamp('01/01/3000','dd/mm/yyyy'));


  --corrispondenza CLASSIFICATORE B
  select classif_id into classif_id_b_new
  from siac_t_class clnew where 
  clnew.ente_proprietario_id = ente_prop_dest_id
  and clnew.classif_code=rec4.classif_code_b
  and clnew.classif_desc=rec4.classif_desc_b
  and clnew.validita_inizio=rec4.validita_inizio_b
  and coalesce(clnew.validita_fine, to_timestamp('01/01/3000','dd/mm/yyyy'))=coalesce(rec4.validita_fine_b, to_timestamp('01/01/3000','dd/mm/yyyy'))
  and exists (select 1 from  siac_r_class_fam_tree rtnew where rtnew.classif_fam_tree_id=classif_fam_tree_id_b_new and rtnew.classif_id=clnew.classif_id);


INSERT INTO 
  siac.siac_r_class
(
  classif_a_id,
  classif_b_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
VALUES (
  classif_id_a_new,
  classif_id_b_new,
  rec4.validita_inizio_coppia_old,
  rec4.validita_fine_coppia_old,
 ente_prop_dest_id,
 login_operaz
);

RETURN NEXT;
  end loop;

raise notice 'dopo rec4: %', clock_timestamp()::varchar;
------fine classificatori
return;
exception
when no_data_found THEN
raise notice 'nessun dato trovato';
when others  THEN
 raise notice 'errore % % ', SQLERRM, SQLSTATE;
--raise notice 'altro errore';
return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;