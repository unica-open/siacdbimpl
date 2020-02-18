/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_crea_ente_da_modello (
  modello varchar,
  cf_code varchar,
  denominazione varchar,
  validita_ini timestamp
)
RETURNS TABLE (
  tabella varchar
) AS
$body$
DECLARE
rec record;
rec2 record;
rec3 record;
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
sql_primary_key_upd varchar;
sql_primary_key_upd2 varchar;
sql_primary_key_upd3 varchar;
sql_primary_key_upd4 varchar;
sql_primary_key_upd5 varchar;
sql_primary_key_upd6 varchar;
sql_primary_key_upd7 varchar;
sql_primary_key_upd8 varchar;
sql_primary_key_upd9 varchar;
sql_primary_key_upd10 varchar;
sql_primary_key_upd11 varchar;
sql_primary_key_upd12 varchar;
sql_primary_key_upd13 varchar;
sql_primary_key_upd14 varchar;
sql_primary_key_upd15 varchar;
login_operaz varchar;
anno_validita_inizio varchar;

table_name_pk varchar;
name_pk varchar;
field_pk VARCHAR;
field_code VARCHAR;
ente_prop_id integer;
cf varchar;
maxclass integer;
minclass integer;
delta integer;
ente_prop_origine_id integer;
rec4 record;
classif_fam_tree_id_a_new integer;
classif_id_a_new integer;
classif_fam_tree_id_b_new integer;
classif_id_b_new integer;
BEGIN
contatore:=1;
contatore2:=1;
login_operaz:='fnc_siac_bko_crea_ente_da_modello';

anno_validita_inizio:=to_char(validita_ini,'yyyy');
cf:=cf_code;
cf=fnc_siac_random_user();
cf=substr(cf,1,16);


/*sql_primary_key_upd4:='SELECT SETVAL(''siac_t_ente_proprietario_ente_proprietario_id_seq'', COALESCE(MAX(ente_proprietario_id),0)+1,false ) FROM siac_t_ente_proprietario';
  EXECUTE sql_primary_key_upd4;*/
  
select max(ente_proprietario_id) + 1 into ente_prop_id from siac_t_ente_proprietario;

  
--raise notice 'ente_prop_id: % ',ente_prop_id;

INSERT INTO 
  siac.siac_t_ente_proprietario
(
  ente_proprietario_id,
  codice_fiscale,
  ente_denominazione,
  validita_inizio,
  validita_fine,
  data_creazione,
  data_modifica,
  data_cancellazione,
  login_operazione
)
select 
ente_prop_id,
cf,
denominazione,
validita_inizio,
validita_fine,
data_creazione,
data_modifica,
data_cancellazione,
login_operaz
from siac_t_ente_proprietario where ente_proprietario_id
in (select em.ente_proprietario_id from siac_r_ente_proprietario_model em, siac_d_ente_proprietario_tipo m where
m.eptipo_id=em.eptipo_id and m.eptipo_code=modello)
and data_cancellazione is null
;

/*sql_primary_key_upd4:='SELECT SETVAL(''siac_t_ente_proprietario_ente_proprietario_id_seq'', COALESCE(MAX(ente_proprietario_id),0)+1,false ) FROM siac_t_ente_proprietario';
  EXECUTE sql_primary_key_upd4;*/

select 
ente_proprietario_id into ente_prop_origine_id
from siac_t_ente_proprietario where ente_proprietario_id
in (select em.ente_proprietario_id from siac_r_ente_proprietario_model em, siac_d_ente_proprietario_tipo m where
m.eptipo_id=em.eptipo_id and m.eptipo_code=modello)
and data_cancellazione is null;

--raise notice 'ente_prop_origine_id: % ',ente_prop_origine_id;

-- TABELLE D che non dipendono da altre tabelle
for rec in 
    select tb.table_name from (
    select table_name from  information_schema.tables where table_schema='siac' and table_name like 'siac_d%'
    except
    SELECT distinct  tc.table_name
    FROM
    information_schema.table_constraints AS tc
    JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    WHERE constraint_type = 'FOREIGN KEY' AND
    ccu.table_name<>'siac_t_ente_proprietario'
    and tc.constraint_schema='siac' and
    tc.table_name like 'siac_d%') tb where tb.table_name not in ('siac_d_ente_proprietario_tipo','siac_d_file_tipo')
    union
       SELECT distinct  tc.table_name 
    FROM
    information_schema.table_constraints AS tc
    JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    WHERE constraint_type = 'FOREIGN KEY' AND
    ccu.table_name<>'siac_t_ente_proprietario'
    and tc.constraint_schema='siac' and
    tc.table_name like 'siac_d%' and ccu.table_name not like 'siac_d%'
    and tc.table_name not in ('siac_d_ente_proprietario_tipo','siac_d_file_tipo')
        order by 1        
loop 
    tabella_nome:=rec.table_name;

-- TROVO CAMPO PRIMARY KEY   
    select cu.column_name INTO primary_key_campo from INFORMATION_SCHEMA.KEY_COLUMN_USAGE cu,information_schema.table_constraints tc 
    where cu.table_schema=tc.table_schema and tc.constraint_name=cu.constraint_name and tc.table_schema = 'siac' 
    and tc.table_name = rec.table_name and tc.constraint_type='PRIMARY KEY';
   
-- TROVO SEQUENCE ASSOCIATA A PK
    primary_key_seq:=pg_get_serial_sequence(tabella_nome, primary_key_campo);
    
    --raise notice 'Primary key: % ',primary_key_seq;
   
-- COMPONGO QUERY PER AGGIORNARE SEQUENCE ASSOCIATA A PK
    sql_primary_key_upd:='SELECT SETVAL('''||primary_key_seq||''',COALESCE(MAX('||primary_key_campo||'),0)+1,false ) FROM '||tabella_nome;
    
    --raise notice 'sql_primary_key_upd: % ',sql_primary_key_upd;
    
-- AGGIORNARNO SEQUENCE ASSOCIATA A PK
    EXECUTE sql_primary_key_upd;
    
-- PER OGNI TABELLA D, TROVO ELENCO CAMPI PER COSTRUIRE INSERT, NON INCLUDENDO CAMPO ID (PK)     
    for r in SELECT cl.column_name  FROM information_schema.columns cl WHERE cl.table_schema = 'siac' and cl.table_name =rec.table_name 
    except 
    select cu.column_name from INFORMATION_SCHEMA.KEY_COLUMN_USAGE cu,information_schema.table_constraints tc 
    where cu.table_schema=tc.table_schema and tc.constraint_name=cu.constraint_name and tc.table_schema = 'siac' 
    and tc.table_name = rec.table_name and tc.constraint_type='PRIMARY KEY'
    --trovato le colonne meno la primary key che, essendo un serial, si autogenera   
    loop    
      if contatore=1 then
      tabella_campo:=r.column_name||',';
      ELSE
      tabella_campo:=tabella_campo||r.column_name||',';
      end if;
      contatore:=contatore+1;
      RETURN NEXT;
	end loop;
    
-- ELENCO CAMPI PER INSERT    

-- ELIMINO L'ULTIMA VIRGOLA
    tabella_campo= substring(tabella_campo from 1 for char_length(tabella_campo)-1);
-- ELENCO CAMPI DESTINAZIOE DELL'INSERT     
    elenco_campi=tabella_campo;
-- ELENCO CAMPI CON VALORI PER L'INSERT (L'ENTE PROPRIETARIO SOSTITUITO CON VALORE IN INPUT)  
    tabella_campo=replace(tabella_campo, 'ente_proprietario_id', ente_prop_id::varchar);
   
-- COMPONGO QUERY PER INSERIMENTO DATI
    stringone:='insert into '|| tabella_nome ||'('||elenco_campi||') select ' || tabella_campo || ' from ' || tabella_nome || ' 
    where ente_proprietario_id ='||ente_prop_origine_id ||' and data_cancellazione is null';
    
   --insert into tmp2 values(rec.table_name,sql_primary_key_upd,stringone);   

--ESEGUO QUERY PER INSERIMENTO DATI   

--raise notice 'tab: % ',rec.table_name;

 EXECUTE stringone;
    
    tabella_campo= null; 
	contatore:=1; 

 	RETURN NEXT;

end loop;

-- TABELLE D che dipendono da altre tabelle D
for rec2 in 
      SELECT distinct  tc.table_name
    FROM
    information_schema.table_constraints AS tc
    JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    WHERE constraint_type = 'FOREIGN KEY' AND
    ccu.table_name<>'siac_t_ente_proprietario'
    and tc.constraint_schema='siac' and
    tc.table_name like 'siac_d%' and ccu.table_name like 'siac_d%'
    and tc.table_name not in ('siac_d_ente_proprietario_tipo','siac_d_file_tipo')
    order by 1    
loop 
   tabella_nome2:=rec2.table_name;
   
--trovo tabella pk collegata tramite tabell fk
select table_name,constraint_name into table_name_pk, name_pk from information_schema.table_constraints where 
 table_schema='siac' and constraint_name in (select 
unique_constraint_name pk 
 from INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc where constraint_name in (select constraint_name from 
information_schema.table_constraints where table_name=tabella_nome2 and table_schema='siac'  and constraint_type='FOREIGN KEY' and constraint_name  like 'siac_d%' )
and constraint_schema='siac');

--TROVO CAMPO PK
select column_name into field_pk
from INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE where table_schema='siac' and constraint_name=name_pk;

--TROVO CAMPO CODE (per join dinamica)
field_code=replace(field_pk, '_id', '_code');
-- TROVO CAMPO PRIMARY KEY   
    select cu.column_name INTO primary_key_campo2 from INFORMATION_SCHEMA.KEY_COLUMN_USAGE cu,information_schema.table_constraints tc 
    where cu.table_schema=tc.table_schema and tc.constraint_name=cu.constraint_name and tc.table_schema = 'siac' 
    and tc.table_name = rec2.table_name and tc.constraint_type='PRIMARY KEY';
   
-- TROVO SEQUENCE ASSOCIATA A PK
    primary_key_seq2:=pg_get_serial_sequence(tabella_nome2, primary_key_campo2);
   
-- COMPONGO QUERY PER AGGIORNARE SEQUENCE ASSOCIATA A PK
    sql_primary_key_upd2:='SELECT SETVAL('''||primary_key_seq2||''',COALESCE(MAX('||primary_key_campo2||'),0)+1,false ) FROM '||tabella_nome2;
    
-- AGGIORNARNO SEQUENCE ASSOCIATA A PK
   -- EXECUTE sql_primary_key_upd2;

-- PER OGNI TABELLA D, TROVO ELENCO CAMPI PER COSTRUIRE INSERT, NON INCLUDENDO CAMPO ID (PK)     
    for r in SELECT cl.column_name  FROM information_schema.columns cl WHERE cl.table_schema = 'siac' and cl.table_name =rec2.table_name 
    except 
    select cu.column_name from INFORMATION_SCHEMA.KEY_COLUMN_USAGE cu,information_schema.table_constraints tc 
    where cu.table_schema=tc.table_schema and tc.constraint_name=cu.constraint_name and tc.table_schema = 'siac' 
    and tc.table_name = rec2.table_name and tc.constraint_type='PRIMARY KEY'
    --trovato le colonne meno la primary key che, essendo un serial, si autogenera   
    loop    
      if contatore2=1 then
      tabella_campo2:=rec2.table_name||'.'||r.column_name||',';
      ELSE
      tabella_campo2:=tabella_campo2||rec2.table_name||'.'||r.column_name||',';
      end if;
      contatore2:=contatore2+1;
      RETURN NEXT;
	end loop;
    
-- ELENCO CAMPI PER INSERT    

-- ELIMINO L'ULTIMA VIRGOLA
    tabella_campo2= substring(tabella_campo2 from 1 for char_length(tabella_campo2)-1);
-- ELENCO CAMPI DESTINAZIOE DELL'INSERT     
    elenco_campi2=tabella_campo2;
    elenco_campi2:=replace(elenco_campi2,tabella_nome2||'.' , ' ');
-- ELENCO CAMPI CON VALORI PER L'INSERT (L'ENTE PROPRIETARIO SOSTITUITO CON VALORE IN INPUT)  
    tabella_campo2=replace(tabella_campo2, tabella_nome2||'.'||'ente_proprietario_id', ente_prop_id::varchar);
    tabella_campo2=replace(tabella_campo2,tabella_nome2||'.'||field_pk , 't2'||'.'||field_pk);
     

-- COMPONGO QUERY PER INSERIMENTO DATI
    stringone2:='insert into '|| tabella_nome2 ||'('||elenco_campi2||') select ' || tabella_campo2 || ' from ' || tabella_nome2||','||table_name_pk||' t1,'||table_name_pk||' t2 '
      || ' where '|| tabella_nome2 ||'.ente_proprietario_id=t1.ente_proprietario_id
      and t1.data_cancellazione is null and t1.'||field_code||'=t2.'||field_code||' and
      t2.ente_proprietario_id = ' || ente_prop_id||' and
      t1.ente_proprietario_id = '|| ente_prop_origine_id ||
      ' and '||tabella_nome2||'.data_cancellazione is null and '||tabella_nome2||'.'||field_pk||'=t1.'||field_pk;
    
    
--insert into tmp2 values(rec2.table_name,sql_primary_key_upd2,stringone2);  

--ESEGUO QUERY PER INSERIMENTO DATI   
   EXECUTE stringone2;
    
    tabella_campo2= null; 
	contatore2:=1; 

 	RETURN NEXT;
end loop;
    
 



/*sql_primary_key_upd3:='SELECT SETVAL(''siac_t_ente_proprietario_ente_proprietario_id_seq'', COALESCE(MAX(ente_proprietario_id),0)+1,false ) FROM siac_t_ente_proprietario';
EXECUTE sql_primary_key_upd3;*/

 
--duplica tabelle cruscotto



/*sql_primary_key_upd5:='SELECT SETVAL(''siac_t_attr_attr_id_seq'',COALESCE(MAX(attr_id),0)+1,false ) FROM siac_t_attr';
EXECUTE sql_primary_key_upd5;*/


INSERT INTO
  siac.siac_t_attr
(
  attr_code,
  attr_desc,
  attr_tipo_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select
a.attr_code,
a.attr_desc,
b2.attr_tipo_id,
validita_ini,
ente_prop_id,
'SETUP'
from siac_t_attr a, siac_d_attr_tipo b, siac_d_attr_tipo b2
 where a.ente_proprietario_id = 1 and a.data_cancellazione is null and
 b.attr_tipo_id=a.attr_tipo_id
 and b2.attr_tipo_code=b.attr_tipo_code and b2.ente_proprietario_id=ente_prop_origine_id;




/*++++++++++++++++*/

/*sql_primary_key_upd13:='SELECT SETVAL(''siac_t_class_fam_tree_classif_fam_tree_id_seq'',COALESCE(MAX(classif_fam_tree_id),0)+1,false ) FROM siac_t_class_fam_tree;';
EXECUTE sql_primary_key_upd13;

sql_primary_key_upd13:='SELECT SETVAL(''siac_t_class_classif_id_seq'', COALESCE(MAX(classif_id),0)+1,false ) FROM siac_t_class';
EXECUTE sql_primary_key_upd13;

sql_primary_key_upd14:='SELECT SETVAL(''siac_r_class_fam_tree_classif_classif_fam_tree_id_seq'', COALESCE(MAX(classif_classif_fam_tree_id),0)+1,false ) FROM siac_r_class_fam_tree';
EXECUTE sql_primary_key_upd14;

sql_primary_key_upd14:='SELECT SETVAL(''siac_r_class_classif_classif_id_seq'', COALESCE(MAX(classif_classif_id),0)+1,false ) FROM siac_r_class';
EXECUTE sql_primary_key_upd14;*/

--per ogni testata
for rec in 
select 
tc.classif_fam_tree_id,
tc.class_fam_code,
tc.class_fam_desc,
fm2.classif_fam_id,
tc.validita_inizio,
tc.validita_fine,
fm2.ente_proprietario_id,
tc.data_creazione,
tc.data_modifica,
tc.data_cancellazione,
tc.login_operazione
from siac_t_class_fam_tree tc, siac_d_class_fam fm, siac_d_class_fam fm2
where 
tc.classif_fam_id=fm.classif_fam_id and
tc.ente_proprietario_id=ente_prop_origine_id
and tc.data_cancellazione is null
and fm.classif_fam_code=fm2.classif_fam_code
and fm2.ente_proprietario_id=ente_prop_id
and tc.classif_fam_id not in 
(select classif_fam_id from siac_d_class_fam where class_fam_code='Struttura Amministrativa Contabile')
order by 1
loop

--trovo DELTA = (MAX+1) - MIN



select max(classif_id) into maxclass 
from siac_t_class;


select min(classif_id)  into minclass 
from siac_r_class_fam_tree a,siac_t_class_fam_tree b,siac_d_class_fam ab
 where 
a.classif_fam_tree_id=b.classif_fam_tree_id AND
b.classif_fam_tree_id = rec.classif_fam_tree_id 
and
b.ente_proprietario_id=ente_prop_origine_id
and b.data_cancellazione is null
and ab.classif_fam_id=b.classif_fam_id
and ab.classif_fam_code<>'Struttura Amministrativa Contabile';


delta:=(maxclass-minclass)+1;

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
values
(
rec.class_fam_code,
rec.class_fam_desc,
rec.classif_fam_id,
rec.validita_inizio,
rec.validita_fine,
rec.ente_proprietario_id,
rec.login_operazione
);

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
select 
cla.classif_id+delta,
cla.classif_code,
cla.classif_desc,
cti2.classif_tipo_id,
cla.validita_inizio,
cla.validita_fine,
ente_prop_id,
cla.login_operazione
from siac_t_class cla, siac_d_class_tipo cti,siac_d_class_tipo cti2, siac_r_class_fam_tree gg
where 
cti.classif_tipo_id=cla.classif_tipo_id and 
cti.classif_tipo_code=cti2.classif_tipo_code and
cla.ente_proprietario_id=ente_prop_origine_id and
cti2.ente_proprietario_id=ente_prop_id and 
cla.data_cancellazione is null and
cti.data_cancellazione is null and
cti2.data_cancellazione is null and  
gg.classif_id=cla.classif_id
and gg.classif_fam_tree_id=rec.classif_fam_tree_id
;   

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
ente_prop_id,
rcl1.login_operazione
from siac_r_class_fam_tree rcl1, siac_t_class_fam_tree tc1,siac_t_class_fam_tree tc2
where 
rcl1.classif_fam_tree_id=tc1.classif_fam_tree_id
and tc1.class_fam_code=tc2.class_fam_code
and tc1.validita_inizio=tc2.validita_inizio
and rcl1.ente_proprietario_id=ente_prop_origine_id
and tc2.ente_proprietario_id=ente_prop_id
and rcl1.data_cancellazione is null
and tc1.data_cancellazione is null
and tc2.data_cancellazione is null
and rcl1.classif_fam_tree_id=rec.classif_fam_tree_id
;

/*
--siac_r_class
INSERT INTO 
  siac.siac_r_class
(
  classif_a_id,
  classif_b_id,
  validita_inizio,validita_fine,
  ente_proprietario_id,
  login_operazione
)
select  
cll.classif_a_id+delta,
cll.classif_b_id+delta,
cll.validita_inizio,
cll.validita_fine,
ente_prop_id,
login_operaz 
from siac_r_class cll ,siac_r_class_fam_tree gg , siac_t_class cl
where 
cll.ente_proprietario_id=ente_prop_origine_id
and cll.data_cancellazione is null
and 
gg.classif_id=cll.classif_a_id 
 and 
gg.classif_fam_tree_id=rec.classif_fam_tree_id
and cl.classif_id=cll.classif_a_id
and exists (select 1 from siac_t_class bb where bb.classif_id=cll.classif_a_id+delta)
and exists (select 1 from siac_t_class bb where bb.classif_id=cll.classif_b_id+delta);*/


RETURN NEXT;
end loop;

/*sql_primary_key_upd13:='SELECT SETVAL(''siac_t_class_fam_tree_classif_fam_tree_id_seq'',COALESCE(MAX(classif_fam_tree_id),0)+1,false ) FROM siac_t_class_fam_tree;';
EXECUTE sql_primary_key_upd13;

sql_primary_key_upd13:='SELECT SETVAL(''siac_t_class_classif_id_seq'', COALESCE(MAX(classif_id),0)+1,false ) FROM siac_t_class';
EXECUTE sql_primary_key_upd13;

sql_primary_key_upd14:='SELECT SETVAL(''siac_r_class_fam_tree_classif_classif_fam_tree_id_seq'', COALESCE(MAX(classif_classif_fam_tree_id),0)+1,false ) FROM siac_r_class_fam_tree';
EXECUTE sql_primary_key_upd14;

sql_primary_key_upd14:='SELECT SETVAL(''siac_r_class_classif_classif_id_seq'', COALESCE(MAX(classif_classif_id),0)+1,false ) FROM siac_r_class';
EXECUTE sql_primary_key_upd14;*/

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
and dfa.classif_fam_desc<>'Struttura Amministrativa Contabile'
and dfb.classif_fam_desc<>'Struttura Amministrativa Contabile'
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
  fanew.ente_proprietario_id = ente_prop_id and
  fanew.class_fam_code=fanold.class_fam_code  and
  fanew.class_fam_desc=fanold.class_fam_desc and
  fanew.validita_inizio=fanold.validita_inizio 
  and coalesce(fanew.validita_fine, to_timestamp('01/01/3000','dd/mm/yyyy'))=coalesce(fanold.validita_fine, to_timestamp('01/01/3000','dd/mm/yyyy'));

  
  --corrispondenza CLASSIFICATORE A
  select classif_id into classif_id_a_new
  from siac_t_class clnew where clnew.ente_proprietario_id = ente_prop_id
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
  fanew.ente_proprietario_id = ente_prop_id and
  fanew.class_fam_code=fanold.class_fam_code  and
  fanew.class_fam_desc=fanold.class_fam_desc and
  fanew.validita_inizio=fanold.validita_inizio 
  and coalesce(fanew.validita_fine, to_timestamp('01/01/3000','dd/mm/yyyy'))=coalesce(fanold.validita_fine, to_timestamp('01/01/3000','dd/mm/yyyy'));


  --corrispondenza CLASSIFICATORE B
  select classif_id into classif_id_b_new
  from siac_t_class clnew where 
  clnew.ente_proprietario_id = ente_prop_id
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
 ente_prop_id,
 login_operaz
);

RETURN NEXT;
  end loop;



/*++++++++++++++++*/



/*sql_primary_key_upd5:='SELECT SETVAL(''siac_t_azione_azione_id_seq'', COALESCE(MAX(azione_id),0)+1,false ) FROM siac_t_azione';
EXECUTE sql_primary_key_upd5;*/

-- SIAC_T_AZIONE

INSERT INTO 
  siac.siac_t_azione
(
  azione_code,
  azione_desc,
  azione_tipo_id,
  gruppo_azioni_id,
  urlapplicazione,
  nomeprocesso,
  nometask,
  verificauo,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  data_creazione,
  data_modifica,
  data_cancellazione,
  login_operazione
)
 /*select  
 a.azione_code,
 a.azione_desc,
 at.azione_tipo_id,
 ag2.gruppo_azioni_id,
 a.urlapplicazione,
 a.nomeprocesso,
 a.nometask,
 a.verificauo,
 a.validita_inizio,
 a.validita_fine,
ag2.ente_proprietario_id,
 a.data_creazione,
 a.data_modifica,
 a.data_cancellazione,
 login_operaz
from siac_t_azione a, 
siac_d_gruppo_azioni ag, 
siac_d_azione_tipo at
,siac_d_gruppo_azioni ag2
where 
a.gruppo_azioni_id=ag.gruppo_azioni_id    
and a.azione_tipo_id=at.azione_tipo_id
and a.ente_proprietario_id=ente_prop_origine_id
and ag2.gruppo_azioni_code=ag.gruppo_azioni_code
and ag2.ente_proprietario_id=ente_prop_id
and a.data_cancellazione is null
and ag.data_cancellazione is null
and at.data_cancellazione is null
and ag2.data_cancellazione is null
;*/
select  
 a.azione_code,
 a.azione_desc,
 at2.azione_tipo_id,
 ag2.gruppo_azioni_id,
 a.urlapplicazione,
 a.nomeprocesso,
 a.nometask,
 a.verificauo,
 a.validita_inizio,
 a.validita_fine,
ag2.ente_proprietario_id,
 a.data_creazione,
 a.data_modifica,
 a.data_cancellazione,
login_operaz
from siac_t_azione a, 
siac_d_gruppo_azioni ag, 
siac_d_azione_tipo at
,siac_d_gruppo_azioni ag2
, siac_d_azione_tipo at2
where 
a.gruppo_azioni_id=ag.gruppo_azioni_id    
and a.azione_tipo_id=at.azione_tipo_id
and a.ente_proprietario_id=ente_prop_origine_id
and ag2.gruppo_azioni_code=ag.gruppo_azioni_code
and ag2.ente_proprietario_id=ente_prop_id
and a.data_cancellazione is null
and ag.data_cancellazione is null
and at.data_cancellazione is null
and ag2.data_cancellazione is null
and at2.ente_proprietario_id=ag2.ente_proprietario_id
and at2.azione_tipo_code=at.azione_tipo_code;


INSERT INTO 
siac.siac_r_ruolo_op_azione
(
ruolo_op_id,
azione_id,
validita_inizio,
 ente_proprietario_id,
login_operazione
)
select
ru2.ruolo_op_id,
az2.azione_id,
op.validita_inizio,
ru2.ente_proprietario_id,
 login_operaz
from siac_r_ruolo_op_azione op, siac_t_azione az, siac_d_ruolo_op ru, siac_d_ruolo_op ru2, 
siac_t_azione az2
where op.azione_id=az.azione_id
and op.ruolo_op_id=ru.ruolo_op_id
and op.ente_proprietario_id=ente_prop_origine_id
and ru2.ruolo_op_code=ru.ruolo_op_code
and az.azione_code=az2.azione_code
and ru2.ente_proprietario_id=az2.ente_proprietario_id
and ru2.ente_proprietario_id=ente_prop_id;




INSERT INTO
  siac.siac_d_file_tipo
(
  file_tipo_code,
  file_tipo_desc,
  azione_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select
tb.file_tipo_code,
tb.file_tipo_desc,
b2.azione_id,
tb.validita_inizio,
ente_prop_id,
'SETUP'
from (
select
a.azione_id,
a.file_tipo_code,
a.file_tipo_desc,
b.azione_code,
a.validita_inizio,
'SETUP'
from siac_d_file_tipo a
left outer join siac_t_azione b on (b.azione_id=a.azione_id)
where a.ente_proprietario_id = ente_prop_origine_id 
and a.data_cancellazione is null) tb
left  outer join siac_t_azione b2 on (b2.azione_code=tb.azione_code and b2.ente_proprietario_id=ente_prop_id);



----------tabelle di configurazione R-----------

  

--  sql_primary_key_upd6:='SELECT SETVAL(''siac_r_attr_bil_elem_tipo_attr_bil_elem_tipo_id_seq'', COALESCE(MAX(attr_bil_elem_tipo_id),0)+1,false ) FROM siac_r_attr_bil_elem_tipo';
--EXECUTE sql_primary_key_upd6;
--siac_r_attr_bil_elem_tipo
INSERT INTO siac_r_attr_bil_elem_tipo
( attr_id,
  elem_tipo_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select   
a2.attr_id, 
bt2.elem_tipo_id,
ra.validita_inizio,
--to_timestamp('01/01/2014','dd/mm/yyyy'),
ra.validita_fine,
a2.ente_proprietario_id,
login_operaz
  from siac_r_attr_bil_elem_tipo ra,
siac_d_bil_elem_tipo bt, siac_t_attr a,
siac_d_bil_elem_tipo bt2, siac_t_attr a2
where ra.ente_proprietario_id=ente_prop_origine_id
and bt.elem_tipo_id = ra.elem_tipo_id
and a.attr_id = ra.attr_id
and bt.elem_tipo_code=bt2.elem_tipo_code
and a.attr_code=a2.attr_code
and a2.ente_proprietario_id=ente_prop_id
and ra.data_cancellazione is null
and bt.data_cancellazione is null
and a.data_cancellazione is null
and bt2.data_cancellazione is null
and a2.data_cancellazione is null;


/*sql_primary_key_upd7:='SELECT SETVAL(''siac_r_attr_class_tipo_attr_class_tipo_id_seq'', COALESCE(MAX(attr_class_tipo_id),0)+1,false ) FROM siac_r_attr_class_tipo';
  EXECUTE sql_primary_key_upd7;*/
--siac_r_attr_class_tipo

INSERT INTO 
  siac.siac_r_attr_class_tipo
(
  attr_id,
  classif_tipo_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
   login_operazione
)
select  
a2.attr_id,
bt2.classif_tipo_id,
ra.validita_inizio,
ra.validita_fine,
ente_prop_id,
login_operaz 
from siac_r_attr_class_tipo ra,
siac_d_class_tipo bt,
siac_t_attr a,
siac_d_class_tipo bt2, 
siac_t_attr a2
where ra.ente_proprietario_id=ente_prop_origine_id
and bt.classif_tipo_id = ra.classif_tipo_id
and a.attr_id = ra.attr_id
and bt.classif_tipo_code=bt2.classif_tipo_code
and a.attr_code=a2.attr_code
and a2.ente_proprietario_id=ente_prop_id
and ra.data_cancellazione is null
and bt.data_cancellazione is null
and a.data_cancellazione is null
and bt2.data_cancellazione is null
and a2.data_cancellazione is null;


/* sql_primary_key_upd8:='SELECT SETVAL(''siac_r_bil_elem_tipo_class_tip_elem_tipo_classif_tipo_id_seq'', COALESCE(MAX(elem_tipo_classif_tipo_id),0)+1,false ) FROM siac_r_bil_elem_tipo_class_tip';
  EXECUTE sql_primary_key_upd8;*/
--siac_r_bil_elem_tipo_class_tip

INSERT INTO 
  siac.siac_r_bil_elem_tipo_class_tip
(
  elem_tipo_id,
  classif_tipo_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
    login_operazione
)
select  
a2.elem_tipo_id,
bt2.classif_tipo_id,
ra.validita_inizio,
ra.validita_fine,
ente_prop_id,
login_operaz 
from siac_r_bil_elem_tipo_class_tip ra,
siac_d_class_tipo bt,
siac_d_bil_elem_tipo a,
siac_d_class_tipo bt2, 
siac_d_bil_elem_tipo a2
where ra.ente_proprietario_id=ente_prop_origine_id
and bt.classif_tipo_id = ra.classif_tipo_id
and a.elem_tipo_id = ra.elem_tipo_id
and bt.classif_tipo_code=bt2.classif_tipo_code
and a.elem_tipo_code=a2.elem_tipo_code
and a2.ente_proprietario_id=ente_prop_id
and ra.data_cancellazione is null
and bt.data_cancellazione is null
and a.data_cancellazione is null
and a2.data_cancellazione is null;


--siac_r_bil_elem_tipo_class_tip_elem_code

/*sql_primary_key_upd8:='SELECT SETVAL(''siac_r_bil_elem_tipo_class_ti_elem_tipo_class_tip_elem_code_seq'',COALESCE(MAX(elem_tipo_class_tip_elem_code),0)+1,false ) FROM siac_r_bil_elem_tipo_class_tip_elem_code;';
  EXECUTE sql_primary_key_upd8;*/

INSERT INTO 
  siac.siac_r_bil_elem_tipo_class_tip_elem_code
(
  elem_tipo_id,
  classif_tipo_id,
  elem_code,
  ente_proprietario_id,
  validita_inizio,
  validita_fine,
  login_operazione
)
select  
a2.elem_tipo_id,
bt2.classif_tipo_id,
ra.elem_code,
ente_prop_id,
ra.validita_inizio,
ra.validita_fine,
login_operaz 
from 
siac_r_bil_elem_tipo_class_tip_elem_code ra,
siac_d_class_tipo bt,
siac_d_bil_elem_tipo a,
siac_d_class_tipo bt2, 
siac_d_bil_elem_tipo a2
where ra.ente_proprietario_id=ente_prop_origine_id
and bt.classif_tipo_id = ra.classif_tipo_id
and a.elem_tipo_id = ra.elem_tipo_id
and bt.classif_tipo_code=bt2.classif_tipo_code
and a.elem_tipo_code=a2.elem_tipo_code
and a2.ente_proprietario_id=ente_prop_id
and ra.data_cancellazione is null
and bt.data_cancellazione is null
and a.data_cancellazione is null
and a2.data_cancellazione is null;


INSERT INTO 
  siac.siac_r_bil_elem_tipo_attr_id_elem_code
(
  elem_tipo_id,
  attr_id,
  elem_code,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select 
a2.elem_tipo_id,
bt2.attr_id,
ra.elem_code,
ra.validita_inizio,
ra.validita_fine,
  ente_prop_id,
  login_operaz 
 from
siac_r_bil_elem_tipo_attr_id_elem_code ra
,
siac_t_attr bt, 
siac_d_attr_tipo btt,
siac_d_bil_elem_tipo a,
siac_t_attr bt2, 
siac_d_attr_tipo btt2, 
siac_d_bil_elem_tipo a2
where 
ra.ente_proprietario_id=ente_prop_origine_id
and bt.attr_id = ra.attr_id
and a.elem_tipo_id = ra.elem_tipo_id
and bt.attr_tipo_id=btt.attr_tipo_id
and btt.attr_tipo_code=btt2.attr_tipo_code
and a.elem_tipo_code=a2.elem_tipo_code
and bt2.attr_tipo_id=btt2.attr_tipo_id
and a2.ente_proprietario_id=ente_prop_id
and ra.data_cancellazione is null
and bt.data_cancellazione is null
and a.data_cancellazione is null
and a2.data_cancellazione is null;

--siac_r_attr_entita

/* sql_primary_key_upd9:='SELECT SETVAL(''siac_r_attr_entita_attr_entita_id_seq'', COALESCE(MAX(attr_entita_id),0)+1,false ) FROM siac_r_attr_entita';
  EXECUTE sql_primary_key_upd9;*/

INSERT INTO 
  siac.siac_r_attr_entita
(
  attr_id,
  entita_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select  
a2.attr_id,
bt2.entita_id,
ra.validita_inizio,
ra.validita_fine,
ente_prop_id,
login_operaz 
from siac_r_attr_entita ra,
siac_d_entita bt,
siac_t_attr a,
siac_d_entita bt2, 
siac_t_attr a2
where ra.ente_proprietario_id=ente_prop_origine_id
and bt.entita_id = ra.entita_id
and a.attr_id = ra.attr_id
and bt.entita_code=bt2.entita_code
and a.attr_code=a2.attr_code
and a2.ente_proprietario_id=ente_prop_id
and ra.data_cancellazione is null
and bt.data_cancellazione is null
and a.data_cancellazione is null
and a2.data_cancellazione is null;



--siac_r_bil_tipo_stato_op

/*   sql_primary_key_upd10:='SELECT SETVAL(''siac_r_bil_tipo_stato_op_bil_tipo_stato_id_seq'', COALESCE(MAX(bil_tipo_stato_id),0)+1,false ) FROM siac_r_bil_tipo_stato_op';
  EXECUTE sql_primary_key_upd10;*/

INSERT INTO 
  siac.siac_r_bil_tipo_stato_op
(
bil_tipo_id,
bil_stato_op_id,
validita_inizio,
validita_fine,
ente_proprietario_id,
login_operazione
)
select  
a2.bil_tipo_id,
bt2.bil_stato_op_id,
ra.validita_inizio,
ra.validita_fine,
ente_prop_id,
login_operaz 
from 
siac_r_bil_tipo_stato_op ra,
siac_d_bil_stato_op bt,
siac_d_bil_tipo a,
siac_d_bil_stato_op bt2, 
siac_d_bil_tipo a2
where ra.ente_proprietario_id=ente_prop_origine_id
and bt.bil_stato_op_id = ra.bil_stato_op_id
and a.bil_tipo_id = ra.bil_tipo_id
and bt.bil_stato_op_code=bt2.bil_stato_op_code
and a.bil_tipo_code=a2.bil_tipo_code
and a2.ente_proprietario_id=ente_prop_id
and ra.data_cancellazione is null
and bt.data_cancellazione is null
and a.data_cancellazione is null
and a2.data_cancellazione is null;

--siac_r_movgest_tipo_class_tip
/*   sql_primary_key_upd11:='SELECT SETVAL(''siac_r_movgest_tipo_class_tip_movgest_tipo_classif_tipo_id_seq'', COALESCE(MAX(movgest_tipo_classif_tipo_id),0)+1,false ) FROM siac_r_movgest_tipo_class_tip';
  EXECUTE sql_primary_key_upd11;*/

INSERT INTO 
  siac.siac_r_movgest_tipo_class_tip
(
  movgest_tipo_id,
  classif_tipo_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select  
a2.movgest_tipo_id,
bt2.classif_tipo_id,
ra.validita_inizio,
ra.validita_fine,
ente_prop_id,
login_operaz 
from 
siac_r_movgest_tipo_class_tip ra,
siac_d_class_tipo bt,
siac_d_movgest_tipo a,
siac_d_class_tipo bt2, 
siac_d_movgest_tipo a2
where ra.ente_proprietario_id=ente_prop_origine_id
and bt.classif_tipo_id = ra.classif_tipo_id
and a.movgest_tipo_id = ra.movgest_tipo_id
and bt.classif_tipo_code=bt2.classif_tipo_code
and a.movgest_tipo_code=a2.movgest_tipo_code
and a2.ente_proprietario_id=ente_prop_id
and ra.data_cancellazione is null
and bt.data_cancellazione is null
and a.data_cancellazione is null
and a2.data_cancellazione is null;

--siac_r_ordinativo_tipo_class_tip
/*    sql_primary_key_upd12:='SELECT SETVAL(''siac_r_ordinativo_tipo_class_tip_ord_tipo_classif_tipo_id_seq'', COALESCE(MAX(ord_tipo_classif_tipo_id),0)+1,false ) FROM siac_r_ordinativo_tipo_class_tip';
  EXECUTE sql_primary_key_upd12;*/


INSERT INTO 
  siac.siac_r_ordinativo_tipo_class_tip
(
  ord_tipo_id,
  classif_tipo_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select  
a2.ord_tipo_id,
bt2.classif_tipo_id,
ra.validita_inizio,
ra.validita_fine,
ente_prop_id,
login_operaz 
from 
siac_r_ordinativo_tipo_class_tip ra,
siac_d_class_tipo bt,
siac_d_ordinativo_tipo a,
siac_d_class_tipo bt2, 
siac_d_ordinativo_tipo a2
where ra.ente_proprietario_id=ente_prop_origine_id
and bt.classif_tipo_id = ra.classif_tipo_id
and a.ord_tipo_id = ra.ord_tipo_id
and bt.classif_tipo_code=bt2.classif_tipo_code
and a.ord_tipo_code=a2.ord_tipo_code
and a2.ente_proprietario_id=ente_prop_id
and ra.data_cancellazione is null
and bt.data_cancellazione is null
and a.data_cancellazione is null
and a2.data_cancellazione is null;

/*sql_primary_key_upd13:='SELECT SETVAL(''siac_t_class_classif_id_seq'',COALESCE(MAX(classif_id),0)+1,false ) FROM siac_t_class;';
EXECUTE sql_primary_key_upd13;*/
--siac_t_class (non ad albero)
INSERT INTO 
  siac.siac_t_class
(
  classif_code,
  classif_desc,
  classif_tipo_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select  a.classif_code,
  a.classif_desc,
  ct2.classif_tipo_id,
  a.validita_inizio,
  a.validita_fine,
  ente_prop_id,
  login_operaz 
  from siac_t_class a , siac_d_class_tipo ct,
siac_d_class_tipo ct2
where not exists (select 1 from 
siac_r_class_fam_tree b where b.classif_id=a.classif_id
) and a.ente_proprietario_id=ente_prop_origine_id
and ct.classif_tipo_id=a.classif_tipo_id
and ct2.ente_proprietario_id= ente_prop_id
and ct.classif_tipo_code=ct2.classif_tipo_code;


--------------
--CRUSCOTTO



/*
siac_t_soggetto
siac_r_soggetto_ruolo
siac_t_account
siac_t_gruppo
siac_r_gruppo_account
siac_r_gruppo_ruolo_op
siac_r_account_ruolo_op
siac_r_ruolo_op_azione*/



--siac_t_soggetto
INSERT INTO 
  siac.siac_t_soggetto
(
  soggetto_code,
  soggetto_desc,
  codice_fiscale,
  validita_inizio,
  ambito_id,
  ente_proprietario_id,
  login_operazione,
  login_creazione
)
select 
s.soggetto_code,
s.soggetto_desc,
substr(fnc_siac_random_user(),1,16),
s.validita_inizio,
a2.ambito_id,
ente_prop_id,
login_operaz,
login_operaz
from 
siac_t_soggetto s,
siac_d_ambito a,siac_d_ambito a2 where 
s.ambito_id=a.ambito_id and 
s.ente_proprietario_id=ente_prop_origine_id and
a.ambito_code='Ambito Cruscotto'
and a.ambito_code=a2.ambito_code
and a2.ente_proprietario_id=ente_prop_id
and s.data_cancellazione is null
and a2.data_cancellazione is null;

--siac_r_soggetto_ruolo
INSERT INTO 
  siac.siac_r_soggetto_ruolo
(
  soggetto_id,
  ruolo_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select
s2.soggetto_id,
dr2.ruolo_id,
s.validita_inizio,
ente_prop_id,
login_operaz
from siac_r_soggetto_ruolo sr, siac_t_soggetto s, siac_d_ruolo dr, siac_t_soggetto s2, siac_d_ruolo dr2
where sr.soggetto_id=s.soggetto_id and sr.ruolo_id=dr.ruolo_id
and sr.ente_proprietario_id=ente_prop_origine_id
and sr.data_cancellazione is null
and s.data_cancellazione is null
and dr.data_cancellazione is null
and s2.ente_proprietario_id=dr2.ente_proprietario_id
and dr2.ente_proprietario_id=ente_prop_id
and s.soggetto_code=s2.soggetto_code
and dr.ruolo_code=dr2.ruolo_code;


--siac_t_account
INSERT INTO 
  siac.siac_t_account
(
  account_code,
  nome,
  descrizione,
  soggeto_ruolo_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select
ac.account_code||' - Ente '||ente_prop_id::varchar, --s2.codice_fiscale,--substr(fnc_siac_random_user(),1,16),
ac.nome,
ac.descrizione,
sr2.soggeto_ruolo_id,
ac.validita_inizio,
ac.validita_fine,
ente_prop_id,
login_operaz
from siac_t_account ac, siac_r_soggetto_ruolo sr, siac_t_soggetto s, siac_d_ruolo dr, siac_t_soggetto s2, siac_d_ruolo dr2, siac_r_soggetto_ruolo sr2
where 
ac.ente_proprietario_id=ente_prop_origine_id
and ac.soggeto_ruolo_id=sr.soggeto_ruolo_id
and sr.soggetto_id=s.soggetto_id and sr.ruolo_id=dr.ruolo_id
and sr.data_cancellazione is null
and s.data_cancellazione is null
and dr.data_cancellazione is null
and s2.ente_proprietario_id=dr2.ente_proprietario_id
and dr2.ente_proprietario_id=ente_prop_id
and s.soggetto_code=s2.soggetto_code
and dr.ruolo_code=dr2.ruolo_code
and sr2.soggetto_id=s2.soggetto_id
and sr2.ruolo_id=dr2.ruolo_id;

--siac_t_gruppo

INSERT INTO
siac.siac_t_gruppo
(
gruppo_code,
gruppo_desc,
validita_inizio,
ente_proprietario_id,
login_operazione
)
select 
gruppo_code, 
gruppo_desc, 
validita_inizio, 
ente_prop_id, 
login_operaz 
from siac_t_gruppo  where
ente_proprietario_id = ente_prop_origine_id
and data_cancellazione is null;



--siac_r_gruppo_account
INSERT INTO 
  siac.siac_r_gruppo_account
(
  gruppo_id,
  account_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select  g2.gruppo_id,
  a2.account_id,
  rga.validita_inizio,
  rga.validita_fine,
  ente_prop_id,
  login_operaz from
siac_r_gruppo_account rga, 
siac_t_gruppo g, siac_t_account a,siac_t_gruppo g2, siac_t_account a2
where rga.gruppo_id=g.gruppo_id
and rga.account_id=a.account_id
and rga.ente_proprietario_id=ente_prop_origine_id
and g2.ente_proprietario_id=a2.ente_proprietario_id
and g2.ente_proprietario_id=ente_prop_id
and a.account_code||' - Ente '||ente_prop_id::varchar=a2.account_code
and g.gruppo_code=g2.gruppo_code
and rga.data_cancellazione is null
;


--siac_r_gruppo_ruolo_op
INSERT INTO
  siac.siac_r_gruppo_ruolo_op
(
  gruppo_id,
  ruolo_operativo_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select 
g2.gruppo_id,
 o2.ruolo_op_id,
  rgr.validita_inizio,
  rgr.validita_fine,
  ente_prop_id,
  login_operaz
from siac_r_gruppo_ruolo_op rgr, siac_t_gruppo g, siac_d_ruolo_op o,siac_t_gruppo g2, siac_d_ruolo_op o2
where rgr.gruppo_id=g.gruppo_id
and rgr.ruolo_operativo_id=o.ruolo_op_id
and rgr.ente_proprietario_id=ente_prop_origine_id
and g2.ente_proprietario_id=o2.ente_proprietario_id
and g2.ente_proprietario_id=ente_prop_id
and g.gruppo_code=g2.gruppo_code
and o.ruolo_op_code=o2.ruolo_op_code
and rgr.data_cancellazione is null;

--siac_r_account_ruolo_op

INSERT INTO 
  siac.siac_r_account_ruolo_op
(
  account_id,
  ruolo_operativo_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select   
g2.account_id,
o2.ruolo_op_id,
rgr.validita_inizio,
rgr.validita_fine,
ente_prop_id,
login_operaz from siac_r_account_ruolo_op rgr, siac_t_account g, siac_d_ruolo_op o,siac_t_account g2, siac_d_ruolo_op o2
where 
rgr.account_id=g.account_id
and rgr.ruolo_operativo_id=o.ruolo_op_id
and rgr.ente_proprietario_id=ente_prop_origine_id
and g2.ente_proprietario_id=o2.ente_proprietario_id
and g2.ente_proprietario_id=ente_prop_id
and g.account_code||' - Ente '||ente_prop_id::varchar=g2.account_code
and o.ruolo_op_code=o2.ruolo_op_code
and rgr.data_cancellazione is null;


--siac_r_ruolo_op_azione
INSERT INTO 
  siac.siac_r_ruolo_op_azione
(
  ruolo_op_id,
  azione_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select 
r2.ruolo_op_id,
a2.azione_id,
roa.validita_inizio,
roa.validita_fine,
ente_prop_id,--r2.ente_proprietario_id,
login_operaz
from siac_r_ruolo_op_azione roa ,siac_t_azione a, 
siac_d_ruolo_op rr, siac_d_azione_tipo at, siac_d_gruppo_azioni gra,
siac_t_azione a2,siac_d_azione_tipo at2, siac_d_gruppo_azioni gra2, siac_d_ruolo_op r2
where 
roa.azione_id=a.azione_id
and roa.ruolo_op_id=rr.ruolo_op_id
and rr.ente_proprietario_id=ente_prop_origine_id
and at.azione_tipo_id=a.azione_tipo_id
and gra.gruppo_azioni_id=a.gruppo_azioni_id
and a2.ente_proprietario_id=ente_prop_id
and a2.azione_code=a.azione_code
and at2.azione_tipo_id=a2.azione_tipo_id
and at2.azione_tipo_code=at.azione_tipo_code
and gra2.gruppo_azioni_id=a2.gruppo_azioni_id
and gra2.gruppo_azioni_code=gra.gruppo_azioni_code
and r2.ente_proprietario_id=gra2.ente_proprietario_id
and r2.ruolo_op_code=rr.ruolo_op_code;






------------------ INSERIRE siac_t_periodo

INSERT INTO
  siac.siac_t_periodo
(
  periodo_code,
  periodo_desc,
  data_inizio,
  data_fine,
  validita_inizio,
  validita_fine,
  periodo_tipo_id,
  anno,
  ente_proprietario_id,
  login_operazione
)
select 
a.periodo_code, 
a.periodo_desc, a.data_inizio, a.data_fine,
a.validita_inizio, a.validita_fine,c.periodo_tipo_id , a.anno, 
ente_prop_id,--c.ente_proprietario_id, 
login_operaz 
from siac_t_periodo a, siac_d_periodo_tipo b , siac_d_periodo_tipo c
where 
a.ente_proprietario_id=b.ente_proprietario_id 
and a.ente_proprietario_id = ente_prop_origine_id
and a.periodo_tipo_id = b.periodo_tipo_id
and b.periodo_tipo_code = c.periodo_tipo_code
and c.ente_proprietario_id = ente_prop_id
and a.anno in ( '2014',  '2015',  '2016', '2017')
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null;


------------------ INSERIRE siac_t_bil

INSERT INTO 
  siac.siac_t_bil
(
  bil_code,
  bil_desc,
  bil_tipo_id,
  periodo_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select 
t.bil_code,
t.bil_desc,
bt2.bil_tipo_id,
pe2.periodo_id,
t.validita_inizio,
t.validita_fine,
ente_prop_id,
login_operaz 
  from siac_t_bil t, siac_d_bil_tipo bt,siac_d_bil_tipo bt2, siac_t_periodo pe, siac_t_periodo pe2
where 
t.bil_tipo_id=bt.bil_tipo_id 
and t.ente_proprietario_id=ente_prop_origine_id
and pe.periodo_id=t.periodo_id
and bt2.ente_proprietario_id=ente_prop_id
and bt2.ente_proprietario_id=pe2.ente_proprietario_id
and bt.bil_tipo_code=bt2.bil_tipo_code
and pe.periodo_code=pe2.periodo_code;



INSERT INTO
  siac.siac_r_bil_fase_operativa
(
  bil_id,
  fase_operativa_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select   
t2.bil_id,
d2.fase_operativa_id,
fo.validita_inizio,
fo.validita_fine,
ente_prop_id,--d2.ente_proprietario_id,
login_operaz from 
siac_r_bil_fase_operativa fo, siac_t_bil t,siac_d_fase_operativa d,
siac_t_bil t2,siac_d_fase_operativa d2 
where fo.ente_proprietario_id=ente_prop_origine_id and
fo.bil_id=t.bil_id
and fo.fase_operativa_id=d.fase_operativa_id
and t2.ente_proprietario_id=d2.ente_proprietario_id
and d2.ente_proprietario_id=ente_prop_id
and 
t.bil_code=t2.bil_code
and d.fase_operativa_code=d2.fase_operativa_code;



--siac_r_gestione_ente
INSERT INTO 
  siac.siac_r_gestione_ente
(
  gestione_livello_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select
  ga2.gestione_livello_id,
  ga2.validita_inizio,
  ente_prop_id,--ga2.ente_proprietario_id,
  login_operaz
 from siac_d_gestione_livello ga, siac_d_gestione_livello ga2, siac_r_gestione_ente gr
where ga.ente_proprietario_id=ente_prop_origine_id
and ga.gestione_livello_code=ga2.gestione_livello_code
and ga2.ente_proprietario_id=ente_prop_id
and gr.gestione_livello_id=ga.gestione_livello_id
and ga.data_cancellazione is null
and gr.data_cancellazione is null
and ga2.data_cancellazione is null;


/****************duplica tabelle report birt**************/

--inserimento nuovo ente: report birt

--1,3,8

--2,4,5,7



/*sql_primary_key_upd3:='SELECT SETVAL(''siac_t_report_rep_id_seq'',COALESCE(MAX(rep_id),0)+1,false ) FROM siac_t_report';
  EXECUTE sql_primary_key_upd3;
  
sql_primary_key_upd3:='SELECT SETVAL(''siac_t_report_importi_repimp_id_seq'',COALESCE(MAX(repimp_id),0)+1,false ) FROM siac_t_report_importi';
  EXECUTE sql_primary_key_upd3;
  
sql_primary_key_upd3:='SELECT SETVAL(''siac_r_report_importi_reprimp_id_seq'',COALESCE(MAX(reprimp_id),0)+1,false ) FROM siac_r_report_importi';
  EXECUTE sql_primary_key_upd3; */   


INSERT INTO 
siac.siac_t_report
(
rep_codice,
rep_desc,
rep_birt_codice,
validita_inizio,
validita_fine,
ente_proprietario_id,
login_operazione
)
select 
rep_codice,
rep_desc,
rep_birt_codice,
validita_inizio,
validita_fine,
ente_prop_id, 
login_operaz
from siac_t_report 
where ente_proprietario_id=ente_prop_origine_id
;

INSERT INTO 
  siac.siac_t_report_importi
(
  repimp_codice,
  repimp_desc,
  repimp_importo,
  repimp_modificabile,
  repimp_prog_riga,
  bil_id,
  periodo_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
) 
 select  
a.repimp_codice,
a.repimp_desc,
a.repimp_importo,
a.repimp_modificabile,
a.repimp_prog_riga,
b2.bil_id,
p2.periodo_id,
b2.validita_inizio,
b2.validita_fine,
ente_prop_id, 
login_operaz
from siac_t_report_importi a, 
siac_t_periodo p1,  siac_d_periodo_tipo pt1,
siac_t_periodo p2, siac_t_bil b1, siac_t_bil b2,
 siac_d_periodo_tipo pt2
where 
p1.periodo_id=a.periodo_id
and pt1.periodo_tipo_id=p1.periodo_tipo_id
AND p2.periodo_code=p1.periodo_code
and pt1.periodo_tipo_code=pt2.periodo_tipo_code 
and a.ente_proprietario_id=ente_prop_origine_id 
and p2.ente_proprietario_id=ente_prop_id 
and pt2.ente_proprietario_id=p2.ente_proprietario_id
and pt2.periodo_tipo_id=p2.periodo_tipo_id
and b1.bil_id=a.bil_id
and b1.bil_code=b2.bil_code
and b2.ente_proprietario_id=p2.ente_proprietario_id;


INSERT INTO 
  siac.siac_r_report_importi
(
rep_id,
repimp_id,
posizione_stampa,
validita_inizio,
validita_fine,
ente_proprietario_id,
login_operazione
)
select   
t2.rep_id,
i2.repimp_id,
rr.posizione_stampa,
rr.validita_inizio,
rr.validita_fine,
ente_prop_id,
login_operaz
from siac_r_report_importi rr, 
siac_t_report t , siac_t_report_importi i,
siac_t_report t2 , siac_t_report_importi i2
where
t.rep_id=rr.rep_id
and rr.ente_proprietario_id=ente_prop_origine_id 
and i.repimp_id=rr.repimp_id
and t.rep_codice=t2.rep_codice
and i.repimp_codice=i2.repimp_codice
and i2.ente_proprietario_id=t2.ente_proprietario_id
and t2.ente_proprietario_id=ente_prop_id
and rr.data_cancellazione is null
and t.data_cancellazione is null
and i.data_cancellazione is null
and t2.data_cancellazione is null
and i2.data_cancellazione is null;


--siac_t_forma_giuridica
INSERT INTO 
  siac.siac_t_forma_giuridica
(
  forma_giuridica_istat_codice,
  forma_giuridica_desc,
  forma_giuridica_tipo_id,
  forma_giuridica_cat_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select 
tg.forma_giuridica_istat_codice,
  tg.forma_giuridica_desc,
  tt2.forma_giuridica_tipo_id,
  cg2.forma_giuridica_cat_id,
  tg.validita_inizio,
  tg.validita_fine,
ente_prop_id,
login_operaz
from siac_t_forma_giuridica tg, siac_d_forma_giuridica_cat cg, siac_d_forma_giuridica_tipo tt,
 siac_d_forma_giuridica_cat cg2, siac_d_forma_giuridica_tipo tt2
where 
tg.forma_giuridica_cat_id=cg.forma_giuridica_cat_id
and tt.forma_giuridica_tipo_id=tg.forma_giuridica_tipo_id
and tg.ente_proprietario_id=ente_prop_origine_id
and tt2.ente_proprietario_id=ente_prop_id
and cg2.ente_proprietario_id=ente_prop_id
and cg.forma_giuridica_cat_code=cg2.forma_giuridica_cat_code
and tt.forma_giuridica_tipo_code=tt2.forma_giuridica_tipo_code
and tg.data_cancellazione is null
and cg.data_cancellazione is null
and tt.data_cancellazione is null
and cg2.data_cancellazione is null
and tt2.data_cancellazione is null;



--siac_t_nazione
insert into  siac_t_nazione (
  nazione_code,
  nazione_desc,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select 
  a.nazione_code,
  a.nazione_desc,
  a.validita_inizio,
  ente_prop_id,
  login_operaz
 from siac_t_nazione a, siac_t_ente_proprietario b
where
a.ente_proprietario_id = ente_prop_origine_id
and b.ente_proprietario_id=ente_prop_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and not exists (select 1 from siac_t_nazione a where a.ente_proprietario_id=b.ente_proprietario_id);

--siac_t_provincia
INSERT INTO 
  siac.siac_t_provincia
(
  provincia_istat_code,
  provincia_desc,
  sigla_automobilistica,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select provincia_istat_code,
  a.provincia_desc,
  a.sigla_automobilistica,
  a.validita_inizio,
  a.validita_fine,
  ente_prop_id,
  login_operaz
from siac_t_provincia a, siac_t_ente_proprietario b
where
a.ente_proprietario_id = ente_prop_origine_id
and b.ente_proprietario_id=ente_prop_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and not exists (select 1 from siac_t_provincia a where a.ente_proprietario_id=b.ente_proprietario_id);

--siac_t_comune
INSERT INTO 
  siac.siac_t_comune
(
  comune_istat_code,
  comune_desc,
  validita_inizio,
  validita_fine,
  nazione_id,
  ente_proprietario_id,
  login_operazione,
  comune_belfiore_catastale_code
)
select
a.comune_istat_code,
  a.comune_desc,
  a.validita_inizio,
  a.validita_fine,
  n2.nazione_id,
  ente_prop_id,
  login_operaz,
  a.comune_belfiore_catastale_code
from siac_t_comune a, siac_t_nazione n
 , siac_t_ente_proprietario b, siac_t_nazione n2
where
a.nazione_id=n.nazione_id and
a.ente_proprietario_id = ente_prop_origine_id
and b.ente_proprietario_id=ente_prop_id
and n2.ente_proprietario_id=b.ente_proprietario_id
and n.nazione_code=n2.nazione_code
and a.data_cancellazione is null
and b.data_cancellazione is null
and not exists (select 1 from siac_t_comune a where a.ente_proprietario_id=b.ente_proprietario_id);



--siac_r_comune....

INSERT INTO 
  siac.siac_r_comune_provincia
(
  comune_id,
  provincia_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select 
c2.comune_id,
p2.provincia_id,
  rrr.validita_inizio,
  rrr.validita_fine,
  ente_prop_id,
  login_operaz
from siac_r_comune_provincia rrr , siac_t_comune c, siac_t_provincia p,
siac_t_comune c2, siac_t_provincia p2
where 
rrr.ente_proprietario_id=ente_prop_origine_id
and c.comune_id=rrr.comune_id
and p.provincia_id=rrr.provincia_id
and c2.comune_istat_code=c.comune_istat_code
and p2.provincia_istat_code=p.provincia_istat_code
and c2.ente_proprietario_id=p2.ente_proprietario_id
and c2.ente_proprietario_id=ente_prop_id;
 

INSERT INTO 
  siac.siac_r_comune_regione
(
  comune_id,
  regione_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select 
c2.comune_id,
p2.regione_id,
  rrrr.validita_inizio,
  rrrr.validita_fine,
  ente_prop_id,
  login_operaz
from siac_r_comune_regione rrrr , siac_t_comune c, siac_t_regione p,
siac_t_comune c2, siac_t_regione p2
where 
rrrr.ente_proprietario_id=ente_prop_origine_id
and c.comune_id=rrrr.comune_id
and p.regione_id=rrrr.regione_id
and c2.comune_istat_code=c.comune_istat_code
and p2.regione_istat_codice=p.regione_istat_codice
and c2.ente_proprietario_id=p2.ente_proprietario_id
and c2.ente_proprietario_id=ente_prop_id;


INSERT INTO 
  siac.siac_r_provincia_regione
(
  provincia_id,
  regione_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select 
c2.provincia_id,
p2.regione_id,
  r4.validita_inizio,
  r4.validita_fine,
  ente_prop_id,
  login_operaz
from siac_r_provincia_regione r4 , siac_t_provincia c, siac_t_regione p,
siac_t_provincia c2, siac_t_regione p2
where 
r4.ente_proprietario_id=ente_prop_origine_id
and c.provincia_id=r4.provincia_id
and p.regione_id=r4.regione_id
and c2.provincia_istat_code=c.provincia_istat_code
and p2.regione_istat_codice=p.regione_istat_codice
and c2.ente_proprietario_id=p2.ente_proprietario_id
and c2.ente_proprietario_id=ente_prop_id;

-- siac_t_azione (tipo azione)

/****************fine duplica tabelle report birt**************/

return;
exception
when no_data_found THEN
raise notice 'nessun dato trovato';
when others  THEN
 raise notice 'errore : %  - stato: % ', SQLERRM, SQLSTATE;
--raise notice 'altro errore';
return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;