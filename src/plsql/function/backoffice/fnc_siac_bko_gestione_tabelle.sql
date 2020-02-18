/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_gestione_tabelle (
  schema_in varchar
)
RETURNS TABLE (
  tabella varchar
) AS
$body$
DECLARE
rec record;

BEGIN

delete from bko_r_system_table_type;
delete from bko_r_system_table_action;
delete from bko_r_system_column_action;
delete from bko_t_system_column;
delete from bko_t_system_table;
delete from bko_d_system_column_action;
delete from bko_d_system_table_action;
delete from bko_d_system_table_type;

perform SETVAL('bko_d_system_table_type_stt_id_seq',COALESCE(MAX(stt_id),0)+1,false ) FROM bko_d_system_table_type;
perform SETVAL('bko_d_system_table_action_sa_id_seq',COALESCE(MAX(sa_id),0)+1,false ) FROM bko_d_system_table_action;
perform SETVAL('bko_r_system_column_action_sca_id_seq',COALESCE(MAX(sca_id),0)+1,false ) FROM bko_r_system_column_action;
perform SETVAL('bko_t_system_column_sc_id_seq',COALESCE(MAX(sc_id),0)+1,false ) FROM bko_t_system_column;
perform SETVAL('bko_t_system_table_st_id_seq',COALESCE(MAX(st_id),0)+1,false ) FROM bko_t_system_table;
perform SETVAL('bko_d_system_column_action_ca_id_seq',COALESCE(MAX(ca_id),0)+1,false ) FROM bko_d_system_column_action;
perform SETVAL('bko_d_system_table_action_sa_id_seq',COALESCE(MAX(sa_id),0)+1,false ) FROM bko_d_system_table_action;
perform SETVAL('bko_d_system_table_type_stt_id_seq',COALESCE(MAX(stt_id),0)+1,false ) FROM bko_d_system_table_type;


INSERT INTO 
  siac.bko_d_system_table_type
(
  stt_code,
  stt_desc
)
select distinct 'd','decodifica' from information_schema.tables where table_schema=schema_in and table_type='BASE TABLE'
and substr(table_name,6,1)='d' and not exists(select 1 from bko_d_system_table_type a where a.stt_code=substr(table_name,6,1));

INSERT INTO 
  siac.bko_d_system_table_type
(
  stt_code,
  stt_desc
)
select distinct 't','dato' from information_schema.tables where table_schema=schema_in and table_type='BASE TABLE'
and substr(table_name,6,1)='t' and not exists(select 1 from bko_d_system_table_type a 
where a.stt_code=substr(table_name,6,1));


INSERT INTO 
  siac.bko_d_system_table_type
(
  stt_code,
  stt_desc
)
select distinct 'r','relazione' from information_schema.tables where table_schema=schema_in and table_type='BASE TABLE'
and substr(table_name,6,1)='r' and not exists(select 1 from bko_d_system_table_type a where a.stt_code=substr(table_name,6,1));

INSERT INTO 
  siac.bko_d_system_table_type
(
  stt_code,
  stt_desc
)
select distinct 's','storico' from information_schema.tables where table_schema=schema_in and table_type='BASE TABLE'
and substr(table_name,6,1)='s' and not exists(select 1 from bko_d_system_table_type a where a.stt_code=substr(table_name,6,1));

INSERT INTO 
  siac.bko_d_system_table_type
(
  stt_code,
  stt_desc
)
select distinct 'w','lavoro' from information_schema.tables where table_schema=schema_in and table_type='BASE TABLE'
and substr(table_name,6,1)='w' and not exists(select 1 from bko_d_system_table_type a where a.stt_code=substr(table_name,6,1));



INSERT INTO 
  siac.bko_t_system_table
(
  st_table_oid,
  st_table_name,
  st_table_label
)
 select oid::integer tabella_oid , relname,  relname 
  FROM pg_class,bko_d_system_table_type where 
 relname in
  (select table_name from information_schema.tables where table_schema=schema_in and table_type='BASE TABLE') 
  and 
   substring(relname,6,1)=bko_d_system_table_type.stt_code
    and relname like 'siac\__\_%'
    and not exists 
   (select 1 from bko_t_system_table dd where dd.st_table_name =relname)
   ;   
  
--inserimento colonne che sono FK
 with uno as (
SELECT tc2.table_name AS pk_table, a2.attname AS pk_column,
    rc.unique_constraint_name AS pk_name, a2.attrelid AS pk_column_oid,
    tc.constraint_schema AS schema_name, tc.table_name AS fk_table,
    a.attname AS fk_column, tc.constraint_name AS fk_name,
    a.attrelid AS fk_column_oid
FROM information_schema.constraint_column_usage cu, pg_class c,
    pg_attribute a, pg_class c2, pg_attribute a2,
    information_schema.table_constraints tc,
    information_schema.referential_constraints rc,
    information_schema.table_constraints tc2,
    information_schema.constraint_column_usage cu2,
    bko_t_system_table ee
WHERE c.relname = tc.table_name::name AND a.attname = cu.column_name::name AND
    tc.constraint_name::text = cu.constraint_name::text AND a.attnum > 0 
    AND a.attrelid = c.oid AND c2.relname = tc2.table_name::name AND 
    a2.attname = cu2.column_name::name AND tc2.constraint_name::text = cu2.constraint_name::text AND 
    a2.attnum > 0 AND a2.attrelid = c2.oid AND rc.constraint_name::text = tc.constraint_name::text 
    AND tc2.constraint_name::text = rc.unique_constraint_name::text AND tc.table_schema::text = schema_in::text 
    AND tc.constraint_type::text = 'FOREIGN KEY'::text
    and ee.st_table_name=tc2.table_name
    ),
    due as ( 
    select 
 b.attrelid oid_table,
 a.table_name,a.column_name
 ,a.ordinal_position, e.st_id, a.data_type
from information_schema.columns a, pg_attribute b,--colums ,
  	pg_class c --table
    ,pg_tables d, bko_t_system_table e
 where a.table_schema=schema_in
 and c.oid=b.attrelid
 and d.tablename=c.relname
  and b.attname=a.column_name
 and d.tablename=a.table_name
 and e.st_table_name=d.tablename)
 INSERT INTO 
  siac.bko_t_system_column
(
  sc_column_oid,
  st_column_name,
  st_column_label,
  sc_column_pk_oid,
  st_id,
  sc_type
)
 select 
 due.oid_table,
  due.column_name, 
  due.column_name,
uno.pk_column_oid,
due.st_id,
due.data_type
  from uno, due 
 where 
uno.fk_table=due.table_name
 and due.column_name=uno.fk_column;
 
-- inserisco i campi PK
  INSERT INTO 
  siac.bko_t_system_column
(
  sc_column_oid,
  st_column_name,
  st_column_label,
  sc_column_pk_oid,
  st_id,
  primary_key,
  sc_type
) 
  SELECT 
c.oid,
 cu2.column_name,
  cu2.column_name,
  null,
  e.st_id,
  true,
  f.data_type
FROM information_schema.table_constraints tc2,
    information_schema.constraint_column_usage cu2,
    pg_class c , pg_tables d, bko_t_system_table e,
    information_schema.columns f
WHERE 
f.table_schema= d.schemaname
and cu2.column_name=f.column_name
and d.tablename=f.table_name
and c.relname=tc2.table_name 
and d.tablename=c.relname
and d.schemaname=schema_in and 
e.st_table_name=d.tablename and 
tc2.table_schema=d.schemaname and
tc2.constraint_type::text = 'PRIMARY KEY'::text AND
    cu2.constraint_name::text = tc2.constraint_name::text 
ORDER BY tc2.table_schema, tc2.table_name;

--inserisco tutti i campi che sono pk e non sono fk
 INSERT INTO 
  siac.bko_t_system_column
(
  sc_column_oid,
  st_column_name,
  st_column_label,
  sc_column_pk_oid,
  st_id,
  sc_type
)
  select 
 b.attrelid oid_table,
 a.column_name,
 a.column_name,
 null,
 e.st_id,
f.data_type
from information_schema.columns a, pg_attribute b,--colums ,
  	pg_class c --table
    ,pg_tables d, bko_t_system_table e, information_schema.columns f
 where 
 f.table_schema= a.table_schema
 and a.table_schema=schema_in
 and b.attname=f.column_name
 and d.tablename=f.table_name
 and c.oid=b.attrelid
 and d.tablename=c.relname
  and b.attname=a.column_name
 and d.tablename=a.table_name
 and e.st_table_name=d.tablename
  and not EXISTS
 (select 1 from bko_t_system_column z where z.st_column_name=a.column_name
 and z.sc_column_oid= b.attrelid);

 -- aggiorno bko_t_system_column.sc_pk_id 
 update  bko_t_system_column set  sc_pk_id  = subquery.sc_pk_id_upd from 
 (
 select b.sc_id sc_pk_id_upd,a.st_table_oid from bko_t_system_table a, bko_t_system_column b
 where 
 b.st_id=a.st_id
 ) subquery
 where bko_t_system_column.sc_column_pk_oid=subquery.st_table_oid
 and sc_column_pk_oid is NOT null
 ;
 
INSERT INTO 
  siac.bko_d_system_table_action
(
  sa_code,
  sa_desc
)
VALUES (
'RR',
 'record_visualizzazione'
);

INSERT INTO 
  siac.bko_d_system_table_action
(
  sa_code,
  sa_desc
)
VALUES (
'RU',
 'record_modifica'
);

INSERT INTO 
  siac.bko_d_system_table_action
(
  sa_code,
  sa_desc
)
VALUES (
'RD',
 'record_cancellazione'
);

INSERT INTO 
  siac.bko_d_system_table_action
(
  sa_code,
  sa_desc
)
VALUES (
'RI',
 'record_inserimento'
);

INSERT INTO 
  siac.bko_d_system_column_action
(
  ca_code,
  ca_desc
)
VALUES (
  'FR',
  'campo_visualizzazione'
);

INSERT INTO 
  siac.bko_d_system_column_action
(
  ca_code,
  ca_desc
)
VALUES (
  'FU',
  'campo_modifica'
);

INSERT INTO 
  siac.bko_r_system_table_action
(
  st_id,
  sa_id
)
select a.st_id,b.sa_id from bko_t_system_table a,bko_d_system_table_action b  
where a.st_table_name like 'siac\_d\_%' 
and b.sa_code in('RR','RU');

INSERT INTO 
  siac.bko_r_system_table_type
(
  stt_id,
  st_id
)
select b.stt_id, a.st_id from bko_t_system_table a,bko_d_system_table_type b 
where substr(a.st_table_name,6,1) =b.stt_code 
and a.st_table_name like 'siac\__\_%'
order by 1, 2;


INSERT INTO 
siac.bko_r_system_column_action
(
sc_id,
ca_id
)
select a.sc_id, b.ca_id from bko_t_system_column a, bko_d_system_column_action b  
where  a.st_column_name not in (
'data_cancellazione',
'login_operazione',
'validita_inizio',
'validita_fine',
'data_creazione',
'data_modifica'
);

update bko_t_system_column set sc_order=subquery.ordinal_position
from (
select c.ordinal_position, b.sc_id from 
bko_t_system_table a,
bko_t_system_column b, information_schema.columns c
where
a.st_id=b.st_id
and c.table_name=a.st_table_name
and c.column_name=b.st_column_name
) subquery
where subquery.sc_id=bko_t_system_column.sc_id;


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