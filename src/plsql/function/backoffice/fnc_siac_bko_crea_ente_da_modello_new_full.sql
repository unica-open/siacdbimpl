/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_crea_ente_da_modello_new_full (
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
reczz record;
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
max_record_pdce integer;
min_record_pdce integer;
new_cescat_id integer;
new_pdce_conto_id integer;
new_pdce_conto_id_padre integer;
rec5 record;
BEGIN
contatore:=1;
contatore2:=1;
login_operaz:='fnc_siac_bko_crea_ente_da_modello';

anno_validita_inizio:=to_char(validita_ini,'yyyy');
cf:=cf_code;
cf=fnc_siac_random_user();
cf=substr(cf,1,16);

  
select max(ente_proprietario_id) + 1
 into ente_prop_id from siac_t_ente_proprietario;

  
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



INSERT INTO 
  siac.siac_r_ente_proprietario_tipo
(
  eptipo_id,
  ente_proprietario_id,
  validita_inizio,
  login_operazione
)
select a.eptipo_id,ente_prop_id,
validita_ini,login_operaz
 from siac_d_ente_proprietario_tipo a where a.eptipo_code=modello;


raise notice 'passo 1';

select 
ente_proprietario_id into ente_prop_origine_id
from siac_t_ente_proprietario where ente_proprietario_id
in (select em.ente_proprietario_id from siac_r_ente_proprietario_model em, siac_d_ente_proprietario_tipo m where
m.eptipo_id=em.eptipo_id and m.eptipo_code=modello)
and data_cancellazione is null;

raise notice 'passo 1.1';

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
    tc.table_name like 'siac_d%') tb where tb.table_name not in ('siac_d_ente_proprietario_tipo','siac_d_file_tipo','siac_d_pdce_fam') and 
     tb.table_name not like 'siac_dwh%'
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
    and tc.table_name not in ('siac_d_ente_proprietario_tipo','siac_d_file_tipo','siac_d_pdce_fam')
     and 
     tc.table_name not like 'siac_dwh%'
        order by 1        
loop 

raise notice 'passo 1.2';
    tabella_nome:=rec.table_name;

-- TROVO CAMPO PRIMARY KEY   
    select cu.column_name INTO primary_key_campo from INFORMATION_SCHEMA.KEY_COLUMN_USAGE cu,information_schema.table_constraints tc 
    where cu.table_schema=tc.table_schema and tc.constraint_name=cu.constraint_name and tc.table_schema = 'siac' 
    and tc.table_name = rec.table_name and tc.constraint_type='PRIMARY KEY';
   
raise notice 'passo 1.3';
--raise notice 'tab : %', tabella_nome;
-- TROVO SEQUENCE ASSOCIATA A PK
    primary_key_seq:=pg_get_serial_sequence(tabella_nome, primary_key_campo);
    
    --raise notice 'Primary key: % ',primary_key_seq;
   
-- COMPONGO QUERY PER AGGIORNARE SEQUENCE ASSOCIATA A PK
    sql_primary_key_upd:='SELECT SETVAL('''||primary_key_seq||''',COALESCE(MAX('||primary_key_campo||'),0)+1,false ) FROM '||tabella_nome;
    
    --raise notice 'sql_primary_key_upd: % ',sql_primary_key_upd;
    
-- AGGIORNARNO SEQUENCE ASSOCIATA A PK
    EXECUTE sql_primary_key_upd;
   
raise notice 'passo 1.4'; 
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
    
    raise notice 'passo 1.5';
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
    
    raise notice 'passo 1.6';
    
   --insert into tmp2 values(rec.table_name,sql_primary_key_upd,stringone);   

--ESEGUO QUERY PER INSERIMENTO DATI   
--raise notice 'stringone: % ',stringone;
--raise notice 'tabella: % ',rec.table_name;

 EXECUTE stringone;
    
    tabella_campo= null; 
	contatore:=1; 

 	RETURN NEXT;

end loop;

raise notice 'passo 2';

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
    and tc.table_name not in ('siac_d_ente_proprietario_tipo','siac_d_file_tipo','siac_d_evento','siac_d_flusso_elaborato_mif', 'siac_d_doc_tipo','siac_d_soggetto_classe','siac_d_soggetto_classe_tipo')
    and 
     tc.table_name not like 'siac_dwh%'
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
     -- ' and '||tabella_nome2||'.data_cancellazione is null and '||tabella_nome2||'.'||field_pk||'=t1.'||field_pk;
     ' and '||tabella_nome2||'.data_cancellazione is null and coalesce('||tabella_nome2||'.'||field_pk||',t1.'||field_pk||')=t1.'||field_pk;
    
--insert into tmp2 values(rec2.table_name,sql_primary_key_upd2,stringone2);  

--if tabella_nome2='saic_d_evento' then
--raise notice 'stringone2: % ',stringone2;
--raise notice 'tabella: % ',rec2.table_name;
--end if;

--ESEGUO QUERY PER INSERIMENTO DATI   
   EXECUTE stringone2;
    
    tabella_campo2= null; 
	contatore2:=1; 

 	RETURN NEXT;
end loop;
 
raise notice 'passo 3';   

INSERT INTO 
  siac.siac_d_pdce_fam
(
  pdce_fam_code,
  pdce_fam_desc,
  pdce_fam_segno,
  pdce_livello_legge,
  validita_inizio,
  ente_proprietario_id,
  login_operazione,
  ambito_id
)
select  
  a.pdce_fam_code,
  a.pdce_fam_desc,
  a.pdce_fam_segno,
  a.pdce_livello_legge,
  a.validita_inizio,
  ente_prop_id,
  login_operaz,
  b2.ambito_id
from siac_d_pdce_fam a,
siac_d_ambito b,siac_d_ambito b2
where 
a.ambito_id=b.ambito_id and
a.ente_proprietario_id=ente_prop_origine_id
and b2.ente_proprietario_id=ente_prop_id
and b.ambito_code=b2.ambito_code;

--siac_d_soggetto_classe_tipo
INSERT INTO 
  siac.siac_d_soggetto_classe_tipo
(
  soggetto_classe_tipo_code,
  soggetto_classe_tipo_desc,
  validita_inizio,
  ambito_id,
  ente_proprietario_id,
  login_operazione
)
select 
a.soggetto_classe_tipo_code,
a.soggetto_classe_tipo_desc,
a.validita_inizio,
b2.ambito_id,
ente_prop_id,
login_operaz,
 from siac_d_soggetto_classe_tipo a ,siac_d_ambito b
, siac_d_ambito b2
where 
a.ambito_id=b.ambito_id
and a.ente_proprietario_id=ente_prop_origine_id
abd b2.ente_proprietario_id=ente_prop_id
and b2.ambito_code=b.ambito_code
and a.data_cancellazione is null
and b.data_cancellazione is null
and b.data_cancellazione is null;

--siac_d_soggetto_classe
INSERT INTO 
  siac.siac_d_soggetto_classe
(
  soggetto_classe_tipo_id,
  soggetto_classe_code,
  soggetto_classe_desc,
  validita_inizio,
  ambito_id,
  ente_proprietario_id,
  login_operazione
)
SELECT b2.soggetto_classe_tipo_id,
a.soggetto_classe_code,a.soggetto_classe_desc,
a.validita_inizio,b2.ambito_id,
ente_prop_id,
login_operaz
 from siac_d_soggetto_classe a, siac_d_soggetto_classe_tipo b,
siac_d_soggetto_classe_tipo b2
where a.ente_proprietario_id=ente_prop_origine_id
and a.soggetto_classe_tipo_id=b.soggetto_classe_tipo_id
and b2.ente_proprietario_id=ente_prop_id
and b2.soggetto_classe_tipo_code=b.soggetto_classe_tipo_code
and a.data_cancellazione is null
and b.data_cancellazione is null
and b.data_cancellazione is null;


--siac_d_doc_tipo
INSERT INTO 
  siac.siac_d_doc_tipo
(
  doc_tipo_code,
  doc_tipo_desc,
  doc_fam_tipo_id,
  doc_gruppo_tipo_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select a.doc_tipo_code,
a.doc_tipo_desc,
t2.doc_fam_tipo_id,
e2.doc_gruppo_tipo_id,
a.validita_inizio,
a.validita_fine,
ente_prop_id,
login_operaz
 from siac_d_doc_tipo a, siac_d_doc_fam_tipo t1, siac_d_doc_fam_tipo t2,
siac_d_doc_gruppo e1,siac_d_doc_gruppo e2
where 
a.doc_fam_tipo_id=t1.doc_fam_tipo_id
and a.ente_proprietario_id=t1.ente_proprietario_id
and t1.ente_proprietario_id = ente_prop_origine_id
and e1.doc_gruppo_tipo_id=a.doc_gruppo_tipo_id
and a.ente_proprietario_id=e1.ente_proprietario_id
and e1.ente_proprietario_id = ente_prop_origine_id
and t2.ente_proprietario_id=e2.ente_proprietario_id
and t2.ente_proprietario_id = ente_prop_id
and e2.ente_proprietario_id = ente_prop_id 
and t1.doc_fam_tipo_code=t2.doc_fam_tipo_code
and e1.doc_gruppo_tipo_code=e2.doc_gruppo_tipo_code
and a.doc_gruppo_tipo_id is not null
and a.data_cancellazione is null 
and t1.data_cancellazione is null
and e1.data_cancellazione is null;

INSERT INTO 
  siac.siac_d_doc_tipo
(
  doc_tipo_code,
  doc_tipo_desc,
  doc_fam_tipo_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select 
a.doc_tipo_code,
a.doc_tipo_desc,
t2.doc_fam_tipo_id,
a.validita_inizio,
a.validita_fine,
ente_prop_id,
login_operaz
 from siac_d_doc_tipo a, siac_d_doc_fam_tipo t1, siac_d_doc_fam_tipo t2
where 
a.doc_fam_tipo_id=t1.doc_fam_tipo_id
and a.ente_proprietario_id=t1.ente_proprietario_id
and t1.ente_proprietario_id = ente_prop_origine_id
and t1.doc_fam_tipo_code=t2.doc_fam_tipo_code
and t2.ente_proprietario_id = ente_prop_id
and a.data_cancellazione is null 
and t1.data_cancellazione is null
and not exists (select 1 from siac_d_doc_tipo z where z.ente_proprietario_id=t2.ente_proprietario_id and z.doc_tipo_code=a.doc_tipo_code);

 
--siac_d_evento
INSERT INTO 
  siac.siac_d_evento
(
  evento_code,
  evento_desc,
  evento_tipo_id,
  collegamento_tipo_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
 select a.evento_code,a.evento_desc,e2.evento_tipo_id,
t2.collegamento_tipo_id,validita_ini,
--a.validita_inizio,
 ente_prop_id
 ,a.login_operazione from 
 siac_d_evento a,
 siac_d_collegamento_tipo t1,siac_d_collegamento_tipo t2,siac_d_evento_tipo e1,siac_d_evento_tipo e2
 where 
 a.ente_proprietario_id=t1.ente_proprietario_id and
 t1.ente_proprietario_id = ente_prop_origine_id
 and e1.ente_proprietario_id = ente_prop_origine_id
 and t1.data_cancellazione is null 
 and t1.collegamento_tipo_code=t2.collegamento_tipo_code 
 and e1.evento_tipo_code=e2.evento_tipo_code
 and t2.ente_proprietario_id = ente_prop_id
 and e2.ente_proprietario_id = ente_prop_id 
 and a.data_cancellazione is null 
 and a.collegamento_tipo_id=t1.collegamento_tipo_id
 and a.evento_tipo_id=e1.evento_tipo_id
 UNION
 select a.evento_code,a.evento_desc,NULL,
t2.collegamento_tipo_id,validita_ini,
--a.validita_inizio,
 ente_prop_id
 ,a.login_operazione from 
 siac_d_evento a,
 siac_d_collegamento_tipo t1,siac_d_collegamento_tipo t2
 where 
 a.ente_proprietario_id=t1.ente_proprietario_id and
 t1.ente_proprietario_id = ente_prop_origine_id
 and t1.data_cancellazione is null 
 and t1.collegamento_tipo_code=t2.collegamento_tipo_code 
  and t2.ente_proprietario_id = ente_prop_id
  and a.data_cancellazione is null 
 and a.collegamento_tipo_id=t1.collegamento_tipo_id
 and a.evento_tipo_id is null
 and a.collegamento_tipo_id is not null
union 
 select a.evento_code,a.evento_desc,e2.evento_tipo_id,
null,
validita_ini,
ente_prop_id
 ,a.login_operazione from 
 siac_d_evento a,siac_d_evento_tipo e1,siac_d_evento_tipo e2
 where 
 a.ente_proprietario_id=e1.ente_proprietario_id and
 e1.ente_proprietario_id = ente_prop_origine_id
 and e1.data_cancellazione is null 
  and e1.evento_tipo_code=e2.evento_tipo_code
 and e2.ente_proprietario_id = ente_prop_id 
 and a.data_cancellazione is null 
 and a.evento_tipo_id=e1.evento_tipo_id
  and a.collegamento_tipo_id is null
 and a.evento_tipo_id is not null;

 
--siac_r_causale_ep_tipo_evento_tipo
INSERT INTO 
  siac.siac_r_causale_ep_tipo_evento_tipo
(
  causale_ep_tipo_id,
  evento_tipo_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select 
c2.causale_ep_tipo_id,b2.evento_tipo_id,
a.validita_inizio,a.validita_fine
, ente_prop_id, login_operaz
from
siac_r_causale_ep_tipo_evento_tipo a, siac_d_evento_tipo b, siac_d_causale_ep_tipo c,
siac_d_evento_tipo b2, siac_d_causale_ep_tipo c2
where b.evento_tipo_id=a.evento_tipo_id and c.causale_ep_tipo_id=a.causale_ep_tipo_id
and a.ente_proprietario_id=ente_prop_origine_id and a.data_cancellazione is null
and b2.ente_proprietario_id=ente_prop_id
and c2.ente_proprietario_id=ente_prop_id
and b2.evento_tipo_code=b.evento_tipo_code
and c.causale_ep_tipo_code=c2.causale_ep_tipo_code;


--duplica tabelle cruscotto


INSERT INTO
  siac.siac_t_attr
(
  attr_code,
  attr_desc,
  attr_tipo_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select
a.attr_code,
a.attr_desc,
b2.attr_tipo_id,
a.validita_inizio,
a.validita_fine,
ente_prop_id,
login_operaz
from siac_t_attr a, siac_d_attr_tipo b, siac_d_attr_tipo b2
 where a.ente_proprietario_id = ente_prop_origine_id
 and a.data_cancellazione is null and
 b.attr_tipo_id=a.attr_tipo_id
 and b2.attr_tipo_code=b.attr_tipo_code and b2.ente_proprietario_id=ente_prop_id;
 

INSERT INTO 
  siac.siac_r_doc_tipo_attr
(
  doc_tipo_id,
  attr_id,
  tabella_id,
  "boolean",
  percentuale,
  testo,
  numerico,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select   
b2.doc_tipo_id,
  c2.attr_id,
  a.tabella_id,
  a."boolean",
  a.percentuale,
  a.testo,
  a.numerico,
  a.validita_inizio,
  a.validita_fine,
ente_prop_id,
login_operaz
  from siac_r_doc_tipo_attr a, siac_d_doc_tipo b, siac_t_attr c, siac_d_attr_tipo d, siac_d_doc_fam_tipo e
,siac_d_doc_tipo b2, siac_t_attr c2,siac_d_attr_tipo d2,  siac_d_doc_fam_tipo e2
where a.doc_tipo_id=b.doc_tipo_id
and c.attr_id=a.attr_id
and a.ente_proprietario_id=ente_prop_origine_id
and d.attr_tipo_id=c.attr_tipo_id
and e.doc_fam_tipo_id=b.doc_fam_tipo_id
and b2.ente_proprietario_id=ente_prop_id
and b2.ente_proprietario_id=c2.ente_proprietario_id
and d2.ente_proprietario_id=c2.ente_proprietario_id
and e2.ente_proprietario_id=d2.ente_proprietario_id
and b2.doc_tipo_code=b.doc_tipo_code
and c2.attr_code=c.attr_code
and d2.attr_tipo_code=d.attr_tipo_code
and d2.attr_tipo_id=c2.attr_tipo_id
and e2.doc_fam_tipo_code=e.doc_fam_tipo_code
and b2.doc_fam_tipo_id=e2.doc_fam_tipo_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and b2.data_cancellazione is null
and c2.data_cancellazione is null
and d2.data_cancellazione is null
and e2.data_cancellazione is null
and b.doc_gruppo_tipo_id is null
union
select 
b2.doc_tipo_id,
c2.attr_id,
a.tabella_id,
a."boolean",
a.percentuale,
a.testo,
a.numerico,
a.validita_inizio,
a.validita_fine,
ente_prop_id,
login_operaz
from siac_r_doc_tipo_attr a, siac_d_doc_tipo b, siac_t_attr c, siac_d_attr_tipo d, siac_d_doc_fam_tipo e, siac_d_doc_gruppo f
,siac_d_doc_tipo b2, siac_t_attr c2,siac_d_attr_tipo d2,  siac_d_doc_fam_tipo e2,siac_d_doc_gruppo f2
where a.doc_tipo_id=b.doc_tipo_id
and c.attr_id=a.attr_id
and a.ente_proprietario_id=ente_prop_origine_id
and d.attr_tipo_id=c.attr_tipo_id
and e.doc_fam_tipo_id=b.doc_fam_tipo_id
and f.doc_gruppo_tipo_id=b.doc_gruppo_tipo_id
and b2.ente_proprietario_id=ente_prop_id
and b2.ente_proprietario_id=c2.ente_proprietario_id
and d2.ente_proprietario_id=c2.ente_proprietario_id
and e2.ente_proprietario_id=d2.ente_proprietario_id
and f2.ente_proprietario_id=e2.ente_proprietario_id
and b2.doc_tipo_code=b.doc_tipo_code
and c2.attr_code=c.attr_code
and d2.attr_tipo_code=d.attr_tipo_code
and d2.attr_tipo_id=c2.attr_tipo_id
and e2.doc_fam_tipo_code=e.doc_fam_tipo_code
and b2.doc_fam_tipo_id=e2.doc_fam_tipo_id
and f2.doc_gruppo_tipo_id=b2.doc_gruppo_tipo_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and b2.data_cancellazione is null
and c2.data_cancellazione is null
and d2.data_cancellazione is null
and e2.data_cancellazione is null
and f2.data_cancellazione is null
and b.doc_gruppo_tipo_id is not null;


raise notice 'passo 4';

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
and now() between tc.validita_inizio and COALESCE(tc.validita_fine,now())
and tc.classif_fam_id not in 
(select classif_fam_id from siac_d_class_fam where class_fam_code='Struttura Amministrativa Contabile')
order by 1
loop

select max(classif_id) into maxclass 
from siac_t_class;


select min(a.classif_id)  into minclass 
from siac_r_class_fam_tree a,siac_t_class_fam_tree b,siac_d_class_fam ab
 where 
a.classif_fam_tree_id=b.classif_fam_tree_id AND
b.classif_fam_tree_id = rec.classif_fam_tree_id 
and
b.ente_proprietario_id=ente_prop_origine_id
and b.data_cancellazione is null
and ab.classif_fam_id=b.classif_fam_id
and now() between a.validita_inizio and COALESCE(a.validita_fine,now())
and ab.classif_fam_code<>'Struttura Amministrativa Contabile';


delta:=(maxclass-minclass)+1;

--raise notice 'delta:%', delta;

raise notice 'minclass:%', minclass;
raise notice 'maxclass:%', maxclass;

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
gg.data_cancellazione is null 
and now() between gg.validita_inizio and COALESCE(gg.validita_fine,now())
and gg.classif_id=cla.classif_id
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
and now() between rcl1.validita_inizio and COALESCE(rcl1.validita_fine,now())
and rcl1.classif_fam_tree_id=rec.classif_fam_tree_id
;


RETURN NEXT;
end loop;

raise notice 'passo 5';



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

raise notice 'passo 6';

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
 ente_prop_id,
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
and at2.azione_tipo_code=at.azione_tipo_code
and at2.ente_proprietario_id=ag2.ente_proprietario_id
and ag2.ente_proprietario_id=ente_prop_id
and a.data_cancellazione is null
and ag.data_cancellazione is null
and at.data_cancellazione is null
and ag2.data_cancellazione is null
and at2.data_cancellazione is null
;

raise notice 'passo 7';



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
select distinct
ru2.ruolo_op_id,
az2.azione_id,
op.validita_inizio,
op.validita_fine,
ente_prop_id,
login_operaz
from siac_r_ruolo_op_azione op, siac_t_azione az, siac_d_ruolo_op ru, siac_d_azione_tipo at, siac_d_gruppo_azioni ga,
siac_d_ruolo_op ru2, siac_t_azione az2,siac_d_azione_tipo at2,siac_d_gruppo_azioni ga2
where 
op.azione_id=az.azione_id
and op.ruolo_op_id=ru.ruolo_op_id
and at.azione_tipo_id=az.azione_tipo_id
and ga.gruppo_azioni_id=az.gruppo_azioni_id
and op.ente_proprietario_id=ente_prop_origine_id
and ru2.ruolo_op_code=ru.ruolo_op_code
and az.azione_code=az2.azione_code
and COALESCE(az.nometask,'zzz')=COALESCE(az2.nometask,'zzz')
and at2.azione_tipo_code=at.azione_tipo_code
and ga.gruppo_azioni_code=ga2.gruppo_azioni_code
and ru2.ente_proprietario_id=az2.ente_proprietario_id
and ru2.ente_proprietario_id=at2.ente_proprietario_id
and ru2.ente_proprietario_id=ga2.ente_proprietario_id
and ru2.ente_proprietario_id=ente_prop_id
and op.data_cancellazione is null
and az.data_cancellazione is null
and ru.data_cancellazione is null
and at.data_cancellazione is NULL
and ga.data_cancellazione is null
and az2.data_cancellazione is null
and ru2.data_cancellazione is null
and at2.data_cancellazione is NULL
and ga2.data_cancellazione is null
;


raise notice 'passo 8';

INSERT INTO
  siac.siac_d_file_tipo
(
  file_tipo_code,
  file_tipo_desc,
  azione_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select
tb.file_tipo_code,
tb.file_tipo_desc,
b2.azione_id,
tb.validita_inizio,
tb.validita_fine,
tb.entenew,
login_operaz
from (
select
a.azione_id,
a.file_tipo_code,
a.file_tipo_desc,
b.azione_code,
a.validita_inizio,
a.validita_fine,
ente_prop_id entenew
from siac_d_file_tipo a
left outer join siac_t_azione b on (b.azione_id=a.azione_id)
where a.ente_proprietario_id = ente_prop_origine_id 
and a.data_cancellazione is null) tb
left  outer join siac_t_azione b2 on (b2.azione_code=tb.azione_code and b2.ente_proprietario_id=ente_prop_id);

raise notice 'passo 9';

----------tabelle di configurazione R-----------

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
ente_prop_id,
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
and bt2.ente_proprietario_id=ente_prop_id
and ra.data_cancellazione is null
and bt.data_cancellazione is null
and a.data_cancellazione is null
and bt2.data_cancellazione is null
and a2.data_cancellazione is null;

raise notice 'passo 10';


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
and bt2.ente_proprietario_id=ente_prop_id
and ra.data_cancellazione is null
and bt.data_cancellazione is null
and a.data_cancellazione is null
and bt2.data_cancellazione is null
and a2.data_cancellazione is null;

raise notice 'passo 11';


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
and bt2.ente_proprietario_id=ente_prop_id
and ra.data_cancellazione is null
and bt.data_cancellazione is null
and a.data_cancellazione is null
and a2.data_cancellazione is null;


raise notice 'passo 12';


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
and a2.ente_proprietario_id=bt2.ente_proprietario_id
and ra.data_cancellazione is null
and bt.data_cancellazione is null
and a.data_cancellazione is null
and a2.data_cancellazione is null;

raise notice 'passo 13';

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
and bt2.ente_proprietario_id=ente_prop_id
and btt2.ente_proprietario_id=ente_prop_id
and ra.data_cancellazione is null
and bt.data_cancellazione is null
and a.data_cancellazione is null
and a2.data_cancellazione is null;

raise notice 'passo 14';

--siac_r_attr_entita

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
and bt2.ente_proprietario_id=ente_prop_id
and ra.data_cancellazione is null
and bt.data_cancellazione is null
and a.data_cancellazione is null
and a2.data_cancellazione is null;

raise notice 'passo 15';

--siac_r_bil_tipo_stato_op

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
and bt2.ente_proprietario_id=ente_prop_id
and ra.data_cancellazione is null
and bt.data_cancellazione is null
and a.data_cancellazione is null
and a2.data_cancellazione is null;

raise notice 'passo 16';

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
and bt2.ente_proprietario_id=ente_prop_id
and ra.data_cancellazione is null
and bt.data_cancellazione is null
and a.data_cancellazione is null
and a2.data_cancellazione is null;


raise notice 'passo 17';

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
and bt2.ente_proprietario_id=ente_prop_id
and ra.data_cancellazione is null
and bt.data_cancellazione is null
and a.data_cancellazione is null
and a2.data_cancellazione is null;

raise notice 'passo 18';

sql_primary_key_upd13:='SELECT SETVAL(''siac_t_class_classif_id_seq'',COALESCE(MAX(classif_id),0)+1,false ) FROM siac_t_class;';
EXECUTE sql_primary_key_upd13;
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
select distinct a.classif_code,
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
and ct.classif_tipo_code=ct2.classif_tipo_code
and a.data_cancellazione is null
and ct.data_cancellazione is null
and ct2.data_cancellazione is null;

raise notice 'passo 19';

--------------
--CRUSCOTTO

--siac_t_soggetto
--siac_r_soggetto_ruolo
--siac_t_account
--siac_t_gruppo
--siac_r_gruppo_account
--siac_r_gruppo_ruolo_op
--siac_r_account_ruolo_op
--siac_r_ruolo_op_azione



--siac_t_soggetto
INSERT INTO 
  siac.siac_t_soggetto
(
  soggetto_code,
  soggetto_desc,
  codice_fiscale,
  validita_inizio,
  validita_fine,
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
s.validita_fine,
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

raise notice 'passo 20';

--siac_r_soggetto_ruolo
INSERT INTO 
  siac.siac_r_soggetto_ruolo
(
  soggetto_id,
  ruolo_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select
s2.soggetto_id,
dr2.ruolo_id,
s.validita_inizio,
s.validita_fine,
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

raise notice 'passo 21';


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

raise notice 'passo 22';

--siac_t_gruppo

INSERT INTO
siac.siac_t_gruppo
(
gruppo_code,
gruppo_desc,
validita_inizio,
validita_fine,
ente_proprietario_id,
login_operazione
)
select 
gruppo_code, 
gruppo_desc, 
validita_inizio,
validita_fine, 
ente_prop_id, 
login_operaz 
from siac_t_gruppo  where
ente_proprietario_id = ente_prop_origine_id
and data_cancellazione is null;

raise notice 'passo 23';


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

raise notice 'passo 24';

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

raise notice 'passo 25';

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

raise notice 'passo 26';



raise notice 'passo 27';

-- siac_t_periodo

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
ente_prop_id,
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

raise notice 'passo 28';

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

raise notice 'passo 29';

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
ente_prop_id,
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

raise notice 'passo 30';


--siac_r_gestione_ente
INSERT INTO 
  siac.siac_r_gestione_ente
(
  gestione_livello_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select
  ga2.gestione_livello_id,
  ga2.validita_inizio,ga2.validita_fine,
  ente_prop_id,
  login_operaz
 from siac_d_gestione_livello ga, siac_d_gestione_livello ga2, siac_r_gestione_ente gr
where ga.ente_proprietario_id=ente_prop_origine_id
and ga.gestione_livello_code=ga2.gestione_livello_code
and ga2.ente_proprietario_id=ente_prop_id
and gr.gestione_livello_id=ga.gestione_livello_id
and ga.data_cancellazione is null
and gr.data_cancellazione is null
and ga2.data_cancellazione is null;

raise notice 'passo 31';

--duplica tabelle report birt

--inserimento nuovo ente: report birt

--1,3,8

--2,4,5,7

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

raise notice 'passo 32';

INSERT INTO 
  siac.siac_t_report_importi
(
  repimp_codice,
  repimp_desc,
  repimp_importo,
  repimp_modificabile,
  repimp_progr_riga,
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
a.repimp_progr_riga,
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

raise notice 'passo 33';

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

raise notice 'passo 34';

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

raise notice 'passo 35';


--siac_t_nazione
insert into  siac_t_nazione (
  nazione_code,
  nazione_desc,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select 
  a.nazione_code,
  a.nazione_desc,
  a.validita_inizio,
  a.validita_fine,
  ente_prop_id,
  login_operaz
 from siac_t_nazione a, siac_t_ente_proprietario b
where
a.ente_proprietario_id = ente_prop_origine_id
and b.ente_proprietario_id=ente_prop_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and not exists (select 1 from siac_t_nazione a where a.ente_proprietario_id=b.ente_proprietario_id);

raise notice 'passo 36';

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

raise notice 'passo 37';

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

raise notice 'passo 38';

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
and c2.comune_belfiore_catastale_code=c.comune_belfiore_catastale_code
and p2.provincia_istat_code=p.provincia_istat_code
and c2.ente_proprietario_id=p2.ente_proprietario_id
and c2.ente_proprietario_id=ente_prop_id;
 
raise notice 'passo 39';

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
and c2.comune_belfiore_catastale_code=c.comune_belfiore_catastale_code
and p2.regione_istat_codice=p.regione_istat_codice
and c2.ente_proprietario_id=p2.ente_proprietario_id
and c2.ente_proprietario_id=ente_prop_id;

raise notice 'passo 40';

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

raise notice 'passo 41';

-- siac_t_azione (tipo azione)


--cassa economale
INSERT INTO 
  siac.siac_t_cassa_econ
(
  cassaecon_code,
  cassaecon_desc,
  cassaecon_resp,
  cassaecon_cc,
  cassaecon_limiteimporto,
  cassa_tipo_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select 
a.cassaecon_code, a.cassaecon_desc, a.cassaecon_resp, a.cassaecon_cc,
a.cassaecon_limiteimporto,b2.cassaecon_tipo_id , a.validita_inizio, a.validita_fine,
ente_prop_id,   login_operaz
from siac_t_cassa_econ a, siac_d_cassa_econ_tipo b, siac_d_cassa_econ_tipo b2
where 
a.ente_proprietario_id = ente_prop_origine_id
and b.cassaecon_tipo_id=a.cassa_tipo_id
and b2.ente_proprietario_id = ente_prop_id
and b2.cassaecon_tipo_code=b.cassaecon_tipo_code
and a.data_cancellazione is null
and b.data_cancellazione is null
and b2.data_cancellazione is null
and not exists (select 1 from siac_t_cassa_econ a2 where a2.cassaecon_code=a.cassaecon_code and a2.cassa_tipo_id=b2.cassaecon_tipo_id
and a2.ente_proprietario_id=b2.ente_proprietario_id
);

raise notice 'passo 41bis';


INSERT INTO 
  siac.siac_r_account_ruolo_op_cassa_econ
(
  account_id,
  ruolo_op_id,
  cassaecon_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select 
a2.account_id, b2.ruolo_op_id, d2.cassaecon_id,  e.validita_inizio,e.validita_fine,
ente_prop_id,   login_operaz
 from 
 siac_t_account a, 
 siac_d_ruolo_op b, 
 siac_t_cassa_econ d
 ,siac_r_account_ruolo_op_cassa_econ e,
  siac_t_account a2, 
 siac_d_ruolo_op b2, 
 siac_t_cassa_econ d2
where
a.account_id=e.account_id
and b.ruolo_op_id=e.ruolo_op_id
and d.cassaecon_id=e.cassaecon_id
and e.ente_proprietario_id= ente_prop_origine_id
and e.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d.data_cancellazione is null
and a2.ente_proprietario_id=ente_prop_id
and a2.ente_proprietario_id=b2.ente_proprietario_id
and b2.ente_proprietario_id=d2.ente_proprietario_id
and a.account_code=a2.account_code
and b.ruolo_op_code=b2.ruolo_op_code
and d.cassaecon_code=d2.cassaecon_code;

raise notice 'passo 41ter';


INSERT INTO 
  siac.siac_r_account_cassa_econ
(
  account_id,
  cassaecon_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select 
a2.account_id, 
d2.cassaecon_id,  
e.validita_inizio,
e.validita_fine,
ente_prop_id,
login_operaz
 from 
 siac_t_account a, siac_t_cassa_econ d
 ,siac_r_account_cassa_econ e,
  siac_t_account a2, 
 siac_t_cassa_econ d2
where
a.account_id=e.account_id
and d.cassaecon_id=e.cassaecon_id
and e.ente_proprietario_id= ente_prop_origine_id
and e.data_cancellazione is null
and a.data_cancellazione is null
and d.data_cancellazione is null
and a2.ente_proprietario_id=ente_prop_id
and d2.ente_proprietario_id=ente_prop_id
and a2.account_code=a.account_code||' - Ente '||a2.ente_proprietario_id::varchar
and d2.cassaecon_code=d.cassaecon_code;

raise notice 'passo 41 quat';


INSERT INTO 
  siac.siac_r_cassa_econ_tipo_modpag_tipo
(
  cassaecon_tipo_id,
  cassamodpag_tipo_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
) 
select 
c2.cassaecon_tipo_id, 
b2.cassamodpag_tipo_id, 
a.validita_inizio,
a.validita_fine, 
ente_prop_id, 
login_operaz
from siac_r_cassa_econ_tipo_modpag_tipo a,  
siac_d_cassa_econ_modpag_tipo b,
siac_d_cassa_econ_tipo c,
siac_d_cassa_econ_modpag_tipo b2,
siac_d_cassa_econ_tipo c2
where 
a.cassamodpag_tipo_id=b.cassamodpag_tipo_id
and
a.cassaecon_tipo_id=c.cassaecon_tipo_id
and a.ente_proprietario_id=ente_prop_origine_id
and b2.ente_proprietario_id=ente_prop_id
and b2.ente_proprietario_id=c2.ente_proprietario_id
and b2.cassamodpag_tipo_code=b.cassamodpag_tipo_code
and c2.cassaecon_tipo_code=c.cassaecon_tipo_code
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null;

raise notice 'passo 41 cinq';

INSERT INTO 
  siac.siac_r_accredito_tipo_cassa_econ
(
  accredito_tipo_id,
  cec_accredito_tipo_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select 
a.accredito_tipo_id, 
b2.cec_accredito_tipo_id,
b2.validita_inizio,
b2.validita_fine,
ente_prop_id,
login_operaz
 from siac_r_accredito_tipo_cassa_econ a , siac_d_accredito_tipo_cassa_econ b,
siac_d_accredito_tipo_cassa_econ b2
where a.ente_proprietario_id=ente_prop_origine_id
and b.cec_accredito_tipo_id=a.cec_accredito_tipo_id
and a.accredito_tipo_id is null
and b2.cec_accredito_tipo_code=b.cec_accredito_tipo_code
and b2.ente_proprietario_id=ente_prop_id;

raise notice 'passo 42';

INSERT INTO 
  siac.siac_r_accredito_tipo_cassa_econ
(
  accredito_tipo_id,
  cec_accredito_tipo_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select 
b2.accredito_tipo_id, 
a.cec_accredito_tipo_id,
b2.validita_inizio,
b2.validita_fine,
ente_prop_id,
login_operaz
from siac_r_accredito_tipo_cassa_econ a , siac_d_accredito_tipo b,
siac_d_accredito_tipo b2
where a.ente_proprietario_id=ente_prop_origine_id
and a.cec_accredito_tipo_id is null
and a.accredito_tipo_id=b.accredito_tipo_id
and b2.accredito_tipo_code=b.accredito_tipo_code
and b2.ente_proprietario_id=ente_prop_origine_id;


raise notice 'passo 43';

 --INSERT INTO 
 -- siac.siac_t_cassa_econ_stanz
 INSERT INTO 
  siac.siac_t_cassa_econ_stanz
(
cassaecon_id,
  cassamodpag_tipo_id,
  cassaecon_importo,
  bil_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select 
b2.cassaecon_id,
  d2.cassamodpag_tipo_id,
  a.cassaecon_importo,
  c2.bil_id,
  a.validita_inizio,
  a.validita_fine,
  ente_prop_id,
  login_operaz
 from siac_t_cassa_econ_stanz a,siac_t_cassa_econ b, siac_t_bil c, siac_d_cassa_econ_modpag_tipo d,
siac_d_bil_tipo e, siac_t_periodo f, siac_d_periodo_tipo g,
siac_t_cassa_econ b2, siac_t_bil c2, siac_d_cassa_econ_modpag_tipo d2,
siac_d_bil_tipo e2, siac_t_periodo f2, siac_d_periodo_tipo g2
where b.cassaecon_id=a.cassaecon_id and c.bil_id=a.bil_id
and d.cassamodpag_tipo_id=a.cassamodpag_tipo_id
and a.ente_proprietario_id=ente_prop_origine_id
and e.bil_tipo_id=c.bil_tipo_id
and f.periodo_id=c.periodo_id
and g.periodo_tipo_id=f.periodo_tipo_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and b2.ente_proprietario_id=ente_prop_id
and c2.ente_proprietario_id=ente_prop_id
and d2.ente_proprietario_id=ente_prop_id
and e2.ente_proprietario_id=ente_prop_id
and f2.ente_proprietario_id=ente_prop_id
and g2.ente_proprietario_id=ente_prop_id
and b2.cassaecon_code=b.cassaecon_code
and e2.bil_tipo_id=c2.bil_tipo_id
and f2.periodo_id=c2.periodo_id
and g2.periodo_tipo_id=f2.periodo_tipo_id
and d2.cassamodpag_tipo_code=d.cassamodpag_tipo_code
and e2.bil_tipo_code=e.bil_tipo_code
and f2.periodo_code=f.periodo_code
and g2.periodo_tipo_code=g.periodo_tipo_code;


raise notice 'passo 44'; 
--siac_t_repj_template

INSERT INTO 
  siac.siac_t_repj_template
(
  repjt_code,
  repjt_desc,
  repjt_path,
  repjt_filename,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select   repjt_code,
  repjt_desc,
  repjt_path,
  repjt_filename,
  validita_inizio,
  validita_fine,
  ente_prop_id,
  login_operaz
  from siac_t_repj_template where ente_proprietario_id=ente_prop_origine_id;
  
  

raise notice 'passo 45';

-------------------inizio sezione problematica
--sezione GEN

INSERT INTO 
  siac.siac_r_pdce_fam_class_tipo
(
  pdce_fam_id,
  classif_tipo_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select   
c2.pdce_fam_id,
b2.classif_tipo_id,
a.validita_inizio,
a.validita_fine,
ente_prop_id,
login_operaz 
from siac_r_pdce_fam_class_tipo a, siac_d_class_tipo b, siac_d_pdce_fam c, siac_d_ambito m,
siac_d_class_tipo b2, siac_d_pdce_fam c2, siac_d_ambito m2
where
a.classif_tipo_id=b.classif_tipo_id
and c.pdce_fam_id=a.pdce_fam_id
and a.ente_proprietario_id=ente_prop_origine_id
and m.ambito_id=c.ambito_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and m.data_cancellazione is null
and b2.ente_proprietario_id=ente_prop_id
and b2.ente_proprietario_id=c2.ente_proprietario_id
and b2.classif_tipo_code=b.classif_tipo_code
and c2.pdce_fam_code=c.pdce_fam_code
and m2.ambito_id=c2.ambito_id
and m2.ambito_code=m.ambito_code
and m2.ente_proprietario_id=ente_prop_id
and not exists 
(select 1 from siac_r_pdce_fam_class_tipo aa where aa.pdce_fam_id=c2.pdce_fam_id
and aa.classif_tipo_id=b2.classif_tipo_id and aa.ente_proprietario_id=b2.ente_proprietario_id
);


raise notice 'passo 46';

INSERT INTO 
  siac.siac_r_pdce_fam_class_fam
(
  pdce_fam_id,
  classif_fam_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select   
c2.pdce_fam_id,
b2.classif_fam_id,
a.validita_inizio,
a.validita_fine,
ente_prop_id,
login_operaz 
from siac_r_pdce_fam_class_fam a, siac_d_class_fam b, siac_d_pdce_fam c, siac_d_ambito m,
siac_d_class_fam b2, siac_d_pdce_fam c2, siac_d_ambito m2
where
a.classif_fam_id=b.classif_fam_id
and c.pdce_fam_id=a.pdce_fam_id
and a.ente_proprietario_id=ente_prop_origine_id
and m.ambito_id=c.ambito_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and m.data_cancellazione is null
and b2.ente_proprietario_id=ente_prop_id
and b2.ente_proprietario_id=c2.ente_proprietario_id
and b2.classif_fam_code=b.classif_fam_code
and c2.pdce_fam_code=c.pdce_fam_code
and m2.ambito_id=c2.ambito_id
and m2.ambito_code=m.ambito_code
and m2.ente_proprietario_id=ente_prop_id
and not exists 
(select 1 from siac_r_pdce_fam_class_fam aa where aa.pdce_fam_id=c2.pdce_fam_id
and aa.classif_fam_id=b2.classif_fam_id and aa.ente_proprietario_id=b2.ente_proprietario_id
);


raise notice 'passo 47';

INSERT INTO 
  siac.siac_t_pdce_fam_tree
(
  pdce_fam_code,
  pdce_fam_desc,
  pdce_fam_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione,
  ambito_id
)
select a.pdce_fam_code,
  a.pdce_fam_desc,
  b2.pdce_fam_id,
  a.validita_inizio,
  a.validita_fine,
  ente_prop_id,
  login_operaz,
  m2.ambito_id
   from siac_t_pdce_fam_tree a, siac_d_pdce_fam b,  siac_d_ambito m,
   siac_d_pdce_fam b2,siac_d_ambito m2
where a.pdce_fam_id=b.pdce_fam_id
and a.ente_proprietario_id=ente_prop_origine_id
and m.ambito_id=b.ambito_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and m.data_cancellazione is null
and b2.ente_proprietario_id=ente_prop_id
and b2.pdce_fam_code=b.pdce_fam_code
and m2.ambito_id=b2.ambito_id
and m.ambito_code=m2.ambito_code
and m2.ente_proprietario_id=ente_prop_id
and not exists 
(SELECT 1 from siac_t_pdce_fam_tree d where d.pdce_fam_code=a.pdce_fam_code
and d.ente_proprietario_id=ente_prop_id
and d.ambito_id=m2.ambito_id
)
;


raise notice 'passo 48';
--t_pdce_conto

select max(a.pdce_conto_id)  into max_record_pdce from siac_t_pdce_conto a;

select min(a.pdce_conto_id) into min_record_pdce from 
siac_t_pdce_conto a, siac_t_pdce_fam_tree b, siac_d_pdce_conto_tipo c,
siac_d_ambito d,siac_d_pdce_conto_tipo e, 
siac_t_pdce_fam_tree b2, siac_d_pdce_conto_tipo c2, siac_d_ambito d2,
siac_d_pdce_conto_tipo e2
where b.pdce_fam_tree_id=a.pdce_fam_tree_id
and c.pdce_ct_tipo_id=a.pdce_ct_tipo_id
and a.ente_proprietario_id=ente_prop_origine_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and b.pdce_fam_code=b2.pdce_fam_code
and c.pdce_ct_tipo_code=c2.pdce_ct_tipo_code
and b2.ente_proprietario_id=ente_prop_id
and c2.ente_proprietario_id=b2.ente_proprietario_id
and d.ambito_id=a.ambito_id
and b2.ambito_id=d2.ambito_id
and d2.ambito_code=d.ambito_code
and e.pdce_ct_tipo_id=a.pdce_ct_tipo_id
and e2.ente_proprietario_id=b2.ente_proprietario_id
and e2.pdce_ct_tipo_code=e.pdce_ct_tipo_code
;

delta:=(max_record_pdce-min_record_pdce)+10;

raise notice 'max_record_pdce:%',max_record_pdce;
raise notice 'min_record_pdce:%',min_record_pdce;
raise notice 'delta:%',delta;

------------- inizio prova
for rec5 in
select 
f.pdce_fam_id,f2.pdce_fam_id,
a.pdce_conto_id,a.pdce_conto_id_padre,a.livello,
a.ordine,a.pdce_conto_a_partita,
a.pdce_conto_code,a.pdce_conto_desc,
b2.pdce_fam_tree_id,c2.pdce_ct_tipo_id,
a.cescat_id, a.validita_inizio,a.validita_fine, g2.ambito_id
 from 
siac_t_pdce_conto a, 
siac_t_pdce_fam_tree b, 
siac_d_pdce_conto_tipo c,
siac_d_pdce_fam f,
siac_d_ambito g
,siac_t_pdce_fam_tree b2, 
siac_d_pdce_fam f2,
siac_d_ambito g2,
siac_d_pdce_conto_tipo c2
where 
a.pdce_fam_tree_id=b.pdce_fam_tree_id
and c.pdce_ct_tipo_id=a.pdce_ct_tipo_id
and a.ente_proprietario_id=ente_prop_origine_id
and f.pdce_fam_id=b.pdce_fam_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and f.data_cancellazione is null
and b.pdce_fam_code=b2.pdce_fam_code
and b2.ente_proprietario_id=ente_prop_id
and f2.pdce_fam_id=b2.pdce_fam_id
and f2.pdce_fam_code=f.pdce_fam_code
and g.ambito_id=a.ambito_id
and b.ambito_id=a.ambito_id
and f.ambito_id=a.ambito_id
and g2.ambito_id=b2.ambito_id
and g2.ambito_id=f2.ambito_id
and g2.ambito_code=g.ambito_code
and g2.ente_proprietario_id=ente_prop_id
and c.pdce_ct_tipo_code=c2.pdce_ct_tipo_code
and c2.ente_proprietario_id=b2.ente_proprietario_id
order by a.pdce_conto_id

loop

new_pdce_conto_id:= rec5.pdce_conto_id+delta;
new_pdce_conto_id_padre:=rec5.pdce_conto_id_padre+delta;

raise notice 'new_pdce_conto_id:%',new_pdce_conto_id;

new_cescat_id:= 0;

select b.cescat_id
into new_cescat_id from 
siac_d_cespiti_categoria a, siac_d_cespiti_categoria b
where a.cescat_code=b.cescat_code
and b.ente_proprietario_id=ente_prop_id
and a.cescat_id=rec5.cescat_id;

if new_cescat_id = 0 then
new_cescat_id:= null;
end if;

INSERT INTO 
  siac.siac_t_pdce_conto
(
  pdce_conto_id,
  pdce_conto_code,
  pdce_conto_desc,
  pdce_conto_id_padre,
  pdce_conto_a_partita,
  livello,
  ordine,
  pdce_fam_tree_id,
  pdce_ct_tipo_id,
  cescat_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione,
  login_creazione,
  ambito_id
) values (
new_pdce_conto_id,
rec5.pdce_conto_code,
rec5.pdce_conto_desc,
new_pdce_conto_id_padre,
rec5.pdce_conto_a_partita,
rec5.livello,
rec5.ordine,
rec5.pdce_fam_tree_id,
rec5.pdce_ct_tipo_id,
new_cescat_id,
rec5.validita_inizio,
rec5.validita_fine,
  ente_prop_id,
  login_operaz,
  login_operaz,
  rec5.ambito_id);
  
raise notice 'passo 49';  
 
INSERT INTO 
  siac.siac_r_pdce_conto
(
  pdce_conto_a_id,
  pdce_conto_b_id,
  pdcerel_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione  
) 
select 
p.pdce_conto_a_id+delta,
p.pdce_conto_b_id+delta,
r2.pdcerel_id,
p.validita_inizio,
p.validita_fine,
ente_prop_id,
login_operaz
 from siac_r_pdce_conto p, siac_d_pdce_rel_tipo rrr, siac_d_pdce_rel_tipo r2
 where 
 p.pdcerel_id=rrr.pdcerel_id
 and r2.pdcerel_code=rrr.pdcerel_code
 and r2.ente_proprietario_id=ente_prop_id
 and 
 (
(p.pdce_conto_a_id=rec5.pdce_conto_id and p.pdce_conto_b_id=rec5.pdce_conto_id_padre)
or 
(p.pdce_conto_a_id=rec5.pdce_conto_id_padre and p.pdce_conto_b_id=rec5.pdce_conto_id)
);


raise notice 'passo 50';
end loop;

--siac_r_causale_ep_pdce_conto
--delete from tmp_siac_r_causale_ep_pdce_conto; 

/*create table tmp_siac_r_causale_ep_pdce_conto (
ser_id serial,
causale_ep_id integer,
pdce_conto_id integer,
ente_proprietario_id integer,
pdce_conto_code varchar,
pdce_ct_tipo_code  varchar,
causale_ep_code  varchar,
causale_ep_tipo_code varchar,
ambito_code varchar);*/

insert into
 tmp_siac_r_causale_ep_pdce_conto(
causale_ep_id ,
pdce_conto_id ,
ente_proprietario_id ,
pdce_conto_code ,
pdce_ct_tipo_code  ,
causale_ep_code  ,
causale_ep_tipo_code ,
ambito_code )
select 
a.causale_ep_id,
  a.pdce_conto_id,
  a.ente_proprietario_id,
  b.pdce_conto_code,
  e.pdce_ct_tipo_code,
  c.causale_ep_code,
  f.causale_ep_tipo_code,
  g.ambito_code
  from siac_r_causale_ep_pdce_conto a, siac_t_pdce_conto b, siac_t_causale_ep c, 
siac_d_pdce_conto_tipo e, siac_d_causale_ep_tipo f,siac_d_ambito g
where b.pdce_conto_id=a.pdce_conto_id and c.causale_ep_id=a.causale_ep_id
and e.pdce_ct_tipo_id=b.pdce_ct_tipo_id and f.causale_ep_tipo_id=c.causale_ep_tipo_id
and g.ambito_id=b.ambito_id
and a.ente_proprietario_id=ente_prop_origine_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null;

INSERT INTO 
  siac.siac_r_causale_ep_pdce_conto
(
  causale_ep_id,
  pdce_conto_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select 
 c.causale_ep_id,
b.pdce_conto_id,
 to_timestamp('01/01/2016','dd/mm/yyyy'),
  ente_prop_id,
 login_operaz
 from tmp_siac_r_causale_ep_pdce_conto a,  siac_t_pdce_conto b, siac_d_pdce_conto_tipo e,
siac_t_causale_ep c, 
 siac_d_causale_ep_tipo f,siac_d_ambito g
where b.ente_proprietario_id= ente_prop_id and
c.ente_proprietario_id= ente_prop_id and
e.ente_proprietario_id= ente_prop_id and
f.ente_proprietario_id= ente_prop_id and
g.ente_proprietario_id= ente_prop_id and
b.pdce_ct_tipo_id=e.pdce_ct_tipo_id
and c.causale_ep_tipo_id=f.causale_ep_tipo_id
and g.ambito_id=b.ambito_id
and b.data_cancellazione is null
and c.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and a.causale_ep_code=c.causale_ep_code
and a.pdce_conto_code=b.pdce_conto_code
and a.causale_ep_tipo_code=f.causale_ep_tipo_code
and e.pdce_ct_tipo_code=a.pdce_ct_tipo_code
and a.ambito_code=g.ambito_code;













raise notice 'passo 62';

INSERT INTO 
  siac.siac_r_causale_ep_pdce_conto_oper
(
  causale_ep_pdce_conto_id,
  oper_ep_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
with uno as (select 
f.causale_ep_tipo_code,e.pdce_ct_tipo_code,d.ambito_code, c.causale_ep_code,
b.pdce_conto_code,i.oper_ep_tipo_code,h.oper_ep_code,g.validita_inizio
 from 
 siac_r_causale_ep_pdce_conto_oper g, 
 siac_d_operazione_ep h,siac_d_operazione_ep_tipo i,
  siac_r_causale_ep_pdce_conto a,
siac_t_pdce_conto b, siac_t_causale_ep c, siac_d_ambito d, siac_d_pdce_conto_tipo e, siac_d_causale_ep_tipo f
where 
g.oper_ep_id=h.oper_ep_id
and i.oper_ep_tipo_id=h.oper_ep_tipo_id
and g.causale_ep_pdce_conto_id=a.causale_ep_pdce_conto_id 
and a.pdce_conto_id=b.pdce_conto_id
and a.causale_ep_id=c.causale_ep_id
and e.pdce_ct_tipo_id=b.pdce_ct_tipo_id
and f.causale_ep_tipo_id=c.causale_ep_tipo_id
and a.ente_proprietario_id=ente_prop_origine_id
and b.ambito_id=c.ambito_id
and d.ambito_id=b.ambito_id
)
,
due as (
select 
a2.causale_ep_pdce_conto_id,
b2.pdce_conto_code,c2.causale_ep_code,d2.ambito_code,e2.pdce_ct_tipo_code,f2.causale_ep_tipo_code,
h2.oper_ep_code,i2.oper_ep_tipo_code, h2.oper_ep_id
 from siac_r_causale_ep_pdce_conto a2,
siac_t_pdce_conto b2, siac_t_causale_ep c2, siac_d_ambito d2
, siac_d_pdce_conto_tipo e2, siac_d_causale_ep_tipo f2
, siac_d_operazione_ep h2,siac_d_operazione_ep_tipo i2
   where  
   a2.ente_proprietario_id=ente_prop_id
   and b2.ente_proprietario_id=ente_prop_id
   and c2.ente_proprietario_id=ente_prop_id
  and d2.ente_proprietario_id=ente_prop_id
    and e2.ente_proprietario_id=ente_prop_id
   and f2.ente_proprietario_id=ente_prop_id  
  and h2.ente_proprietario_id=ente_prop_id
   and i2.ente_proprietario_id=ente_prop_id
   and a2.pdce_conto_id=b2.pdce_conto_id
   and a2.causale_ep_id=c2.causale_ep_id
   and b2.ambito_id=d2.ambito_id
     and e2.pdce_ct_tipo_id=b2.pdce_ct_tipo_id
   and f2.causale_ep_tipo_id=c2.causale_ep_tipo_id
and h2.oper_ep_tipo_id=i2.oper_ep_tipo_id)
select 
 due.causale_ep_pdce_conto_id,
  due.oper_ep_id,
  uno.validita_inizio,
  ente_prop_id,
login_operaz
 from uno, due where 
uno.causale_ep_tipo_code=due.causale_ep_tipo_code
and uno.pdce_ct_tipo_code=due.pdce_ct_tipo_code
and uno.ambito_code=due.ambito_code
and uno.causale_ep_code=due.causale_ep_code
and uno.pdce_conto_code=due.pdce_conto_code 
and uno.oper_ep_tipo_code=due.oper_ep_tipo_code
and uno.oper_ep_code=due.oper_ep_code;

with
orig as (
select c.tabella_id,c."boolean",c.percentuale,
  c.testo,c.numerico,c.validita_inizio,
a.pdce_conto_code,b.pdce_ct_tipo_code,d.attr_code,e.attr_tipo_code,
f.ambito_code,g.pdce_fam_code pdce_fam_code_tree,h.pdce_fam_code
 from 
 siac_t_pdce_conto a, siac_d_pdce_conto_tipo b,
siac_r_pdce_conto_attr c, siac_t_attr d, siac_d_attr_tipo e, siac_d_ambito f,  siac_t_pdce_fam_tree g, siac_d_pdce_fam h
 where 
b.pdce_ct_tipo_id=a.pdce_ct_tipo_id
and c.pdce_conto_id=a.pdce_conto_id
and c.ente_proprietario_id=ente_prop_origine_id
and c.attr_id=d.attr_id
and e.attr_tipo_id=d.attr_tipo_id
and f.ambito_id=a.ambito_id
and now() between c.validita_inizio and coalesce(c.validita_fine,now())
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and g.pdce_fam_tree_id=a.pdce_fam_tree_id
and g.pdce_fam_id=h.pdce_fam_id
),
dest as (
select 
 a2.pdce_conto_id, d2.attr_id,
a2.pdce_conto_code,b2.pdce_ct_tipo_code,d2.attr_code,e2.attr_tipo_code, 
f2.ambito_code,g2.pdce_fam_code pdce_fam_code_tree,h2.pdce_fam_code
from siac_t_pdce_conto a2, siac_d_pdce_conto_tipo b2,
siac_t_attr d2,siac_d_attr_tipo e2,siac_d_ambito f2,siac_t_pdce_fam_tree g2, siac_d_pdce_fam h2
where
 b2.pdce_ct_tipo_id=a2.pdce_ct_tipo_id
and e2.attr_tipo_id=d2.attr_tipo_id
and a2.ente_proprietario_id=ente_prop_id
and b2.ente_proprietario_id=ente_prop_id
and d2.ente_proprietario_id=ente_prop_id
and e2.ente_proprietario_id=ente_prop_id
and f2.ente_proprietario_id=ente_prop_id
and g2.ente_proprietario_id=ente_prop_id
and h2.ente_proprietario_id=ente_prop_id
and f2.ambito_id=a2.ambito_id
and g2.pdce_fam_tree_id=a2.pdce_fam_tree_id
and g2.pdce_fam_id=h2.pdce_fam_id
and a2.data_cancellazione is null
and b2.data_cancellazione is null
and d2.data_cancellazione is null
and e2.data_cancellazione is null
and f2.data_cancellazione is null
and g2.data_cancellazione is null
and h2.data_cancellazione is null
)
INSERT INTO 
  siac.siac_r_pdce_conto_attr
(
  pdce_conto_id,
  attr_id,
  tabella_id,
  "boolean",
  percentuale,
  testo,
  numerico,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select dest.pdce_conto_id, dest.attr_id
,
orig.tabella_id,
  orig."boolean",
  orig.percentuale,
  orig.testo,
  orig.numerico,
  orig.validita_inizio
  ,
  ente_prop_id,
  login_operaz
 from orig,dest
where 
orig.pdce_conto_code=dest.pdce_conto_code
and orig.pdce_ct_tipo_code=dest.pdce_ct_tipo_code
and orig.attr_code=dest.attr_code
and orig.attr_tipo_code=dest.attr_tipo_code
and orig.ambito_code=dest.ambito_code
and orig.pdce_fam_code_tree=dest.pdce_fam_code_tree
and orig.pdce_fam_code=dest.pdce_fam_code;


-------------------fine sezione problematica

--siac_t_causale_ep
INSERT INTO 
  siac.siac_t_causale_ep
(
  causale_ep_code,
  causale_ep_desc,
  causale_ep_tipo_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione,
  login_creazione,
  causale_ep_default,
  ambito_id
)
select
a.causale_ep_code,
a.causale_ep_desc,
b2.causale_ep_tipo_id,
a.validita_inizio,
ente_prop_id,
login_operaz,
login_operaz,
a.causale_ep_default,
m2.ambito_id
 from 
siac_t_causale_ep a, siac_d_ambito m,
siac_d_causale_ep_tipo b, siac_d_causale_ep_tipo b2
,siac_d_ambito m2
 where 
a.causale_ep_tipo_id=b.causale_ep_tipo_id
and b2.causale_ep_tipo_code=b.causale_ep_tipo_code
and a.ente_proprietario_id=ente_prop_origine_id
and b2.ente_proprietario_id=ente_prop_id
and m.ambito_id=a.ambito_id
and m2.ente_proprietario_id=b2.ente_proprietario_id
and m2.ambito_code=m.ambito_code
and not exists (select 1 from siac_t_causale_ep c where c.ente_proprietario_id=b2.ente_proprietario_id
and c.causale_ep_code=a.causale_ep_code and c.ambito_id=m2.ambito_id);

raise notice 'passo 61';



raise notice 'passo 63';

with uno as (select b.causale_ep_code, a.validita_inizio,
c.ambito_code,d.evento_code,e.evento_tipo_code
from siac_r_evento_causale a, siac_t_causale_ep b, siac_d_ambito c ,siac_d_evento d, siac_d_evento_tipo e
where a.causale_ep_id=b.causale_ep_id
and
b.ambito_id=c.ambito_id and a.evento_id=d.evento_id
and e.evento_tipo_id=d.evento_tipo_id
and a.ente_proprietario_id=ente_prop_origine_id
AND a.data_cancellazione is null
AND b.data_cancellazione is null
AND c.data_cancellazione is null
AND d.data_cancellazione is null
AND e.data_cancellazione is null
)
, due as (select  
d2.evento_id,b2.causale_ep_id,
b2.causale_ep_code,
c2.ambito_code,d2.evento_code,e2.evento_tipo_code from siac_t_causale_ep b2, siac_d_ambito c2 ,siac_d_evento d2, siac_d_evento_tipo e2
where 
d2.ente_proprietario_id=ente_prop_id
and b2.ente_proprietario_id=ente_prop_id
and c2.ente_proprietario_id=ente_prop_id
and e2.ente_proprietario_id=ente_prop_id
and b2.ambito_id=c2.ambito_id
and d2.evento_tipo_id=e2.evento_tipo_id
)
INSERT INTO 
  siac.siac_r_evento_causale
(
  evento_id,
  causale_ep_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select due.evento_id,due.causale_ep_id, uno.validita_inizio, ente_prop_id,login_operaz from uno, due
WHERE
 uno.causale_ep_code=due.causale_ep_code
and uno.ambito_code=due.ambito_code
and uno.evento_code=due.evento_code
and uno.evento_tipo_code=due.evento_tipo_code
;

raise notice 'passo 64';

INSERT INTO 
  siac.siac_r_causale_ep_stato
(
  causale_ep_id,
  causale_ep_stato_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select 
c2.causale_ep_id,
b2.causale_ep_stato_id,
a.validita_inizio,
ente_prop_id,
login_operaz
 from siac_r_causale_ep_stato a, siac_d_causale_ep_stato b, siac_t_causale_ep c
,siac_d_causale_ep_stato b2, siac_t_causale_ep c2
where a.causale_ep_stato_id=b.causale_ep_stato_id
and a.causale_ep_id=c.causale_ep_id
and a.ente_proprietario_id=ente_prop_origine_id
and b2.ente_proprietario_id=ente_prop_id
and c2.ente_proprietario_id=ente_prop_id
and b2.causale_ep_stato_code=b.causale_ep_stato_code
and c2.causale_ep_code=c.causale_ep_code
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null;

raise notice 'passo 65';

with uno as(
select 
b.classif_code,b.classif_desc,
c.causale_ep_code,d.classif_tipo_code,
e.ambito_code,f.causale_ep_tipo_code, a.validita_inizio
 from siac_r_causale_ep_class a, 
 siac_t_class b, siac_t_causale_ep c, siac_d_class_tipo d, siac_d_ambito e, siac_d_causale_ep_tipo f
where 
a.classif_id=b.classif_id
and a.causale_ep_id=c.causale_ep_id
and d.classif_tipo_id=b.classif_tipo_id
and a.ente_proprietario_id=ente_prop_origine_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.ambito_id=c.ambito_id
and f.causale_ep_tipo_id=c.causale_ep_tipo_id),
due AS( select
a.classif_id,
 a.classif_code,
 a.classif_desc,
 b.classif_tipo_code
 from  
 siac_t_class a,  siac_d_class_tipo b
where 
a.classif_tipo_id=b.classif_tipo_id
and 
a.ente_proprietario_id=ente_prop_id
and a.data_cancellazione is null
and b.data_cancellazione is null),
tre as ( 
select 
a.causale_ep_id,
a.causale_ep_code, b.ambito_code,c.causale_ep_tipo_code from  
siac_t_causale_ep a, siac_d_ambito b, siac_d_causale_ep_tipo c
where a.ambito_id=b.ambito_id
and c.causale_ep_tipo_id=a.causale_ep_tipo_id
and a.ente_proprietario_id=ente_prop_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null)
INSERT INTO 
  siac.siac_r_causale_ep_class
(
causale_ep_id,
classif_id,
validita_inizio,
ente_proprietario_id,
login_operazione
)
select 
tre.causale_ep_id,
due.classif_id,
uno.validita_inizio,
ente_prop_id,
login_operaz
 from uno,due,tre
where uno.classif_code=due.classif_code
and 
uno.classif_tipo_code=due.classif_tipo_code
and 
uno.classif_desc=due.classif_desc
and 
uno.causale_ep_code=tre.causale_ep_code
and 
uno.ambito_code=tre.ambito_code
and
uno.causale_ep_tipo_code=tre.causale_ep_tipo_code;



--siac_t_iva_aliquota
--siac_t_iva_aliquota
INSERT INTO 
  siac.siac_t_iva_aliquota
(
  ivaaliquota_code,
  ivaaliquota_desc,
  ivaaliquota_perc,
  ivaaliquota_perc_indetr,
  ivaop_tipo_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
  select 
  b.ivaaliquota_code,
  b.ivaaliquota_desc,
  b.ivaaliquota_perc,
  b.ivaaliquota_perc_indetr,
  c2.ivaop_tipo_id,
  b.validita_inizio,
  b.validita_fine,
  ente_prop_id,
  login_operaz
   from 
siac_t_iva_aliquota b, siac_d_iva_operazione_tipo c,
siac_d_iva_operazione_tipo c2
where 
c.ivaop_tipo_id=b.ivaop_tipo_id
and 
b.ente_proprietario_id=c.ente_proprietario_id
and b.ente_proprietario_id=ente_prop_origine_id
and c2.ente_proprietario_id=ente_prop_id
and c2.ivaop_tipo_code=c.ivaop_tipo_code;


raise notice 'passo 51';
 
  
--siac_t_iva_prorata
INSERT INTO 
  siac.siac_t_iva_prorata
(
  ivapro_perc,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  data_creazione,
  data_modifica,
  data_cancellazione,
  login_operazione
) select
  ivapro_perc,
  validita_inizio,
  validita_fine,
  ente_prop_id,
  data_creazione,
  data_modifica,
  data_cancellazione,
  login_operaz
from siac_t_iva_prorata
where  ente_proprietario_id=ente_prop_origine_id;


raise notice 'passo 52';

--siac_t_iva_attivita
  INSERT INTO 
  siac.siac_t_iva_attivita
(
  ivaatt_code,
  ivaatt_desc,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  data_creazione,
  data_modifica,
  data_cancellazione,
  login_operazione
)
select  
ivaatt_code,
  ivaatt_desc,
  validita_inizio,
  validita_fine,
  ente_prop_id,
  data_creazione,
  data_modifica,
  data_cancellazione,
  login_operaz from siac_t_iva_attivita
  where ente_proprietario_id=ente_prop_origine_id;
  
raise notice 'passo 53';  

--siac_t_iva_gruppo
INSERT INTO 
  siac.siac_t_iva_gruppo
(
  ivagru_code,
  ivagru_desc,
  ivagru_ivaprecedente,
  ivagru_tipo_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  data_creazione,
  data_modifica,
  data_cancellazione,
  login_operazione
)
select 
a.ivagru_code,
a.ivagru_desc,
a.ivagru_ivaprecedente,
b2.ivagru_tipo_id,
a.validita_inizio,
a.validita_fine,
ente_prop_id,
a.data_creazione,
a.data_modifica,
a.data_cancellazione
login_operaz
from siac_t_iva_gruppo a, siac_d_iva_gruppo_tipo b,
siac_d_iva_gruppo_tipo b2
where 
a.ivagru_tipo_id=b.ivagru_tipo_id
and a.ente_proprietario_id=b.ente_proprietario_id
and a.ente_proprietario_id=ente_prop_origine_id
and b2.ivagru_tipo_code=b.ivagru_tipo_code
and b2.ente_proprietario_id=ente_prop_id;
  
  
raise notice 'passo 54';  

--siac_r_iva_gruppo_attivita
INSERT INTO 
  siac.siac_r_iva_gruppo_attivita
(
  ivagru_id,
  ivaatt_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select 
b2.ivagru_id,
c2.ivaatt_id,
a.validita_inizio,
a.validita_fine,
ente_prop_id,
login_operaz
 from siac_r_iva_gruppo_attivita a, siac_t_iva_gruppo b, siac_t_iva_attivita c, siac_d_iva_gruppo_tipo d,
siac_t_iva_gruppo b2, siac_t_iva_attivita c2,siac_d_iva_gruppo_tipo d2
where b.ivagru_id=a.ivagru_id
and c.ivaatt_id=a.ivaatt_id
and a.ente_proprietario_id=ente_prop_id
and d.ivagru_tipo_id=b.ivagru_tipo_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and b2.ivagru_code=b.ivagru_code
and c2.ivaatt_code=c.ivaatt_code
and b2.ivagru_tipo_id=d2.ivagru_tipo_id
and d2.ivagru_tipo_code=d.ivagru_tipo_code
and b2.ente_proprietario_id=ente_prop_id
and b2.ente_proprietario_id=c2.ente_proprietario_id
and c2.ente_proprietario_id=d2.ente_proprietario_id;

raise notice 'passo 55';

--siac_r_iva_gruppo_chiusura
INSERT INTO 
  siac.siac_r_iva_gruppo_chiusura
(
  ivagru_id,
  ivachi_tipo_id,
  ivagruchitipo_anno,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select 
b2.ivagru_id,
  d2.ivachi_tipo_id,
  a.ivagruchitipo_anno,
  a.validita_inizio,
  a.validita_fine,
  ente_prop_id,
  login_operaz from siac_r_iva_gruppo_chiusura a, siac_t_iva_gruppo b, siac_d_iva_gruppo_tipo c, siac_d_iva_chiusura_tipo d,
siac_t_iva_gruppo b2, siac_d_iva_gruppo_tipo c2, siac_d_iva_chiusura_tipo d2
where b.ivagru_id=a.ivagru_id
and
c.ivagru_tipo_id=b.ivagru_tipo_id
and d.ivachi_tipo_id=a.ivachi_tipo_id
and a.ente_proprietario_id=ente_prop_origine_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and b2.ente_proprietario_id=ente_prop_id
and c2.ente_proprietario_id=b2.ente_proprietario_id
and d2.ente_proprietario_id=c2.ente_proprietario_id
and c2.ivagru_tipo_id=b2.ivagru_tipo_id
and b2.ivagru_code=b.ivagru_code
and c2.ivagru_tipo_code=c.ivagru_tipo_code
and d2.ivachi_tipo_code=d.ivachi_tipo_code;

raise notice 'passo 56';

--siac_r_iva_gruppo_prorata
INSERT INTO 
  siac.siac_r_iva_gruppo_prorata
(
  ivagru_id,
  ivapro_id,
  ivagrupro_anno,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select 
b2.ivagru_id,
  d2.ivapro_id,
  a.ivagrupro_anno,
  a.validita_inizio,
  a.validita_fine,
  ente_prop_id,
  login_operaz from siac_r_iva_gruppo_prorata a, siac_t_iva_gruppo b, siac_d_iva_gruppo_tipo c, siac_t_iva_prorata d,
siac_t_iva_gruppo b2, siac_d_iva_gruppo_tipo c2, siac_t_iva_prorata d2
where b.ivagru_id=a.ivagru_id
and
c.ivagru_tipo_id=b.ivagru_tipo_id
and d.ivapro_id=a.ivapro_id
and a.ente_proprietario_id=ente_prop_origine_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and b2.ente_proprietario_id=ente_prop_id
and c2.ente_proprietario_id=b2.ente_proprietario_id
and d2.ente_proprietario_id=c2.ente_proprietario_id
and c2.ivagru_tipo_id=b2.ivagru_tipo_id
and b2.ivagru_code=b.ivagru_code
and c2.ivagru_tipo_code=c.ivagru_tipo_code
and d2.ivapro_perc=d.ivapro_perc;


raise notice 'passo 57';

--fine duplica tabelle report birt

 
INSERT INTO 
  siac.siac_t_sepa
(
  sepa_paese,
  sepa_iso_code,
  sepa_iban_length,
  validita_inizio,
  nazione_id,
  valuta_id,
  ente_proprietario_id,
  login_operazione
)
select    
d.sepa_paese,
d.sepa_iso_code,
d.sepa_iban_length,
d.validita_inizio,
f2.nazione_id,
e2.valuta_id,
a.ente_proprietario_id,
d.login_operazione 
from siac_t_ente_proprietario a, siac_t_sepa d, siac_d_valuta e, siac_d_valuta e2,
siac_t_nazione f,siac_t_nazione f2
where 
d.ente_proprietario_id=ente_prop_origine_id and 
a.ente_proprietario_id=ente_prop_id and
e.valuta_id=d.valuta_id
and e2.ente_proprietario_id=a.ente_proprietario_id
and e2.valuta_code=e.valuta_code and 
f.nazione_id=d.nazione_id
and f2.ente_proprietario_id=a.ente_proprietario_id
and f2.nazione_code=f.nazione_code and
not exists (select * from siac_t_sepa b where b.ente_proprietario_id=a.ente_proprietario_id and b.sepa_iso_code=d.sepa_iso_code)
order by a.ente_proprietario_id, d.sepa_id;


--siac_r_onere_attivita
--select * from siac_r_onere_attivita 


--siac_r_pdce_conto_class
--SELECT * from siac_r_pdce_conto_class

raise notice 'passo 58';

--siac_t_abi
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
select b.abi_code,
  b.abi_desc,
  b.validita_inizio,
  a.nazione_id,
  ente_prop_id,
  login_operaz 
   from siac_t_abi b,
siac_t_nazione a where a.nazione_code='1'
and b.ente_proprietario_id=ente_prop_origine_id
and a.ente_proprietario_id=ente_prop_id 
and not exists (select 1 from siac_t_abi c where c.ente_proprietario_id=a.ente_proprietario_id and c.abi_code=b.abi_code);

raise notice 'passo 59';
/*
--siac_t_cab
INSERT INTO 
  siac.siac_t_cab
(
  cab_abi,
  cab_code,
  cab_citta,
  cab_indirizzo,
  cab_cap,
  cab_desc,
  cab_provincia,
  abi_id,
  validita_inizio,
  nazione_id,
  ente_proprietario_id,
  login_operazione
)
select
  a.cab_abi,
  a.cab_code,
  a.cab_citta,
  a.cab_indirizzo,
  a.cab_cap,
  a.cab_desc,
  a.cab_provincia,
  c.abi_id,
  a.validita_inizio,
  b2.nazione_id,
  c.ente_proprietario_id,
  c.login_operazione
 from
siac_t_cab a,siac_t_nazione b, siac_t_nazione b2, siac_t_abi c where 
a.nazione_id=b.nazione_id
and a.ente_proprietario_id=ente_prop_origine_id
and b2.ente_proprietario_id=ente_prop_id
and b2.nazione_code=b.nazione_code
and c.abi_code=a.cab_abi
--and c.ente_proprietario_id=b2.ente_proprietario_id
and c.ente_proprietario_id=ente_prop_id
and not exists (select 1 from siac_t_cab z where z.cab_code=a.cab_code and z.ente_proprietario_id=c.ente_proprietario_id)    ;
*/
raise notice 'passo 60';



--new 20160216
INSERT INTO 
  siac_r_pcc_debito_stato_causale
(
  pccdeb_stato_id,
  pcccau_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select 
b2.pccdeb_stato_id,
a2.pcccau_id,
to_timestamp('01/01/2016','dd/mm/yyyy'),
ente_prop_id,
login_operaz
 from siac_d_pcc_causale a, 
siac_d_pcc_debito_stato b,
siac_r_pcc_debito_stato_causale c,
siac_d_pcc_causale a2, 
siac_d_pcc_debito_stato b2
where 
a.pcccau_id=c.pcccau_id
and 
b.pccdeb_stato_id=c.pccdeb_stato_id
and c.ente_proprietario_id=ente_prop_origine_id
and a2.ente_proprietario_id=b2.ente_proprietario_id
and a2.ente_proprietario_id=ente_prop_id
and 
a2.pcccau_code=a.pcccau_code
and 
b2.pccdeb_stato_code=b.pccdeb_stato_code
and not EXISTS
(
select 1 from siac_r_pcc_debito_stato_causale z
where z.pccdeb_stato_id=b2.pccdeb_stato_id
and
z.pcccau_id=a2.pcccau_id
);



 INSERT INTO 
  siac.siac_r_iva_reg_tipo_doc_fam_tipo
(
  doc_fam_tipo_id,
  reg_tipo_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
 select  
 B2.doc_fam_tipo_id, c2.reg_tipo_id, a.validita_inizio,  ente_prop_id,
  login_operaz
 from siac_r_iva_reg_tipo_doc_fam_tipo a , siac_d_doc_fam_tipo b,
 siac_d_iva_registrazione_tipo c,
  siac_d_doc_fam_tipo b2,
 siac_d_iva_registrazione_tipo c2
 where 
 b.doc_fam_tipo_id=a.doc_fam_tipo_id
 and 
 c.reg_tipo_id=a.reg_tipo_id
 and 
 a.ente_proprietario_id=ente_prop_origine_id
 and 
c2.ente_proprietario_id=ente_prop_id
 and 
 b2.ente_proprietario_id=ente_prop_id
 and 
 b2.doc_fam_tipo_code=b.doc_fam_tipo_code
 and 
 c2.reg_tipo_code=c.reg_tipo_code
 and not exists (select 1 from siac_r_iva_reg_tipo_doc_fam_tipo z where z.doc_fam_tipo_id=b2.doc_fam_tipo_id
 and z.reg_tipo_id=c2.reg_tipo_id);
 
 INSERT INTO 
  siac.siac_r_atto_allegato_stampa_tipo_template
(
  attoalst_tipo_id,
  repjt_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
 select 
 c2.attoalst_tipo_id,
 b2.repjt_id, a.validita_inizio, ente_prop_id,
  login_operaz
  from siac_r_atto_allegato_stampa_tipo_template a,
 siac_t_repj_template b, siac_d_atto_allegato_stampa_tipo c,
  siac_t_repj_template b2, siac_d_atto_allegato_stampa_tipo c2
 where b.repjt_id=a.repjt_id
 and 
 c.attoalst_tipo_id=a.attoalst_tipo_id
 and 
 a.ente_proprietario_id=ente_prop_origine_id
 and 
c2.ente_proprietario_id=ente_prop_id
 and 
 b2.ente_proprietario_id=ente_prop_id
 and
 b.repjt_code=b2.repjt_code
 and 
 c.attoalst_tipo_code=c2.attoalst_tipo_code
  and not exists (select 1 from siac_r_atto_allegato_stampa_tipo_template z where 
  z.attoalst_tipo_id=c2.attoalst_tipo_id
 and z.repjt_id=b2.repjt_id);
 
 INSERT INTO 
  siac.siac_r_class_fam_class_tipo
(
  classif_fam_id,
  classif_tipo_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select c2.classif_fam_id,b2.classif_tipo_id, a.validita_inizio,
ente_prop_id,  login_operaz
 from siac_r_class_fam_class_tipo a
, siac_d_class_tipo b, siac_d_class_fam c
, siac_d_class_tipo b2, siac_d_class_fam c2
where
b.classif_tipo_id=a.classif_tipo_id
and 
c.classif_fam_id=a.classif_fam_id
and a.ente_proprietario_id=ente_prop_origine_id
and 
c2.ente_proprietario_id=ente_prop_id
 and 
 b2.ente_proprietario_id=ente_prop_id
 and
 b.classif_tipo_code=b2.classif_tipo_code
 and 
 c.classif_fam_code=c2.classif_fam_code
  and not exists (select 1 from siac_r_class_fam_class_tipo z where 
  z.classif_fam_id=c2.classif_fam_id
 and z.classif_tipo_id=b2.classif_tipo_id);
 
 INSERT INTO 
  siac.siac_r_class_tipo_entita
(
  classif_tipo_id,
  entita_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select c2.classif_tipo_id,
b2.entita_id, a.validita_inizio,ente_prop_id,  login_operaz
 from siac_r_class_tipo_entita a , 
siac_d_entita b,siac_d_class_tipo c,
siac_d_entita b2,siac_d_class_tipo c2
where b.entita_id=a.entita_id
and
c.classif_tipo_id=a.classif_tipo_id
and a.ente_proprietario_id=ente_prop_origine_id
and 
c2.ente_proprietario_id=ente_prop_id
 and 
 b2.ente_proprietario_id=ente_prop_id
 and 
 b.entita_code=b2.entita_code
 and
 c.classif_tipo_code=c2.classif_tipo_code
  and not exists (select 1 from siac_r_class_tipo_entita z where 
  z.classif_tipo_id=c2.classif_tipo_id
 and z.entita_id=b2.entita_id);
 
 
  INSERT INTO 
  siac.siac_t_regione
(
  regione_istat_codice,
  regione_denominazione,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
 select 
 a.regione_istat_codice,
 a.regione_denominazione,
 a.validita_inizio ,
ente_prop_id,  login_operaz
from siac_t_regione  a where a.ente_proprietario_id=ente_prop_origine_id
  and not exists (select 1 from siac_t_regione z where a.regione_denominazione=z.regione_denominazione and
  z.ente_proprietario_id=ente_prop_id );

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
  rrr.validita_inizio,
  rrr.validita_fine,
  ente_prop_id,
  login_operaz
from siac_r_comune_regione rrr , siac_t_comune c, siac_t_regione p,
siac_t_comune c2, siac_t_regione p2
where 
rrr.ente_proprietario_id=ente_prop_origine_id
and c.comune_id=rrr.comune_id
and p.regione_id=rrr.regione_id
and c2.comune_istat_code=c.comune_istat_code
and c2.comune_belfiore_catastale_code=c.comune_belfiore_catastale_code
and p2.regione_istat_codice=p.regione_istat_codice
and c2.ente_proprietario_id=p2.ente_proprietario_id
and c2.ente_proprietario_id=ente_prop_id
and not exists (select 1 from siac_r_comune_regione z where z.comune_id=c2.comune_id
and z.regione_id=p2.regione_id);

--SIRFEL

INSERT INTO 
siac.sirfel_d_modalita_pagamento
(
ente_proprietario_id,
codice,
descrizione
)
select 
ente_prop_id,
codice,
descrizione 
from 
sirfel_d_modalita_pagamento 
where ente_proprietario_id=ente_prop_origine_id;

INSERT INTO 
  siac.sirfel_d_natura
(
  ente_proprietario_id,
  codice,
  descrizione
)
select 
ente_prop_id,
codice,
descrizione 
from 
sirfel_d_natura 
where ente_proprietario_id=ente_prop_origine_id;

INSERT INTO 
  siac.sirfel_d_regime_fiscale
(
  ente_proprietario_id,
  codice,
  descrizione
)
select 
ente_prop_id,
codice,
descrizione 
from 
sirfel_d_regime_fiscale 
where ente_proprietario_id=ente_prop_origine_id;

INSERT INTO 
  siac.sirfel_d_tipo_cassa
(
  ente_proprietario_id,
  codice,
  descrizione
)
select 
ente_prop_id,
codice,
descrizione 
from 
sirfel_d_tipo_cassa 
where ente_proprietario_id=ente_prop_origine_id;

INSERT INTO 
  siac.sirfel_d_tipo_documento
(
  ente_proprietario_id,
  codice,
  descrizione,
  flag_bilancio
)
select 
ente_prop_id,
codice,
descrizione,
  flag_bilancio
from 
sirfel_d_tipo_documento 
where ente_proprietario_id=ente_prop_origine_id;



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