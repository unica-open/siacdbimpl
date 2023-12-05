/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_delete_ente (
  ente_prop_id integer
)
RETURNS void 
AS
$body$
DECLARE
rec record;
stringone varchar;  
stringone2 varchar;
stringone3 varchar;
tabella_nome varchar;
fase varchar;
datipresenti boolean;
level integer;
tab_schema varchar;
trovato integer;
BEGIN

datipresenti:=true;
tab_schema='siac';
level:=0;



stringone2:='CREATE TABLE bko_d_tables_to_delete as select distinct tab_name_out nometabella,0 livello from fnc_siac_bko_tables_fk_dependent (''siac'',''siac_t_ente_proprietario'') where tab_name_out not in (select tab_nome from siac_d_tabella_configurazione_ente);';

execute stringone2;

/*insert into bko_d_tables_to_delete
select distinct tab_name_out,0 from siac.fnc_siac_bko_tables_fk_dependent (
'siac','siac_t_ente_proprietario'
)
where  tab_name_out like 'siac_%'
and  tab_name_out not like 'siac_d%'
and tab_name_out not in ('siac_t_attr',
'siac_t_class_fam_tree',
'siac_t_class',
'siac_r_class_fam_tree',
'siac_r_class',
'siac_t_azione',
'siac_r_ruolo_op_azione',
'siac_d_file_tipo',
'siac_r_attr_bil_elem_tipo',
'siac_r_attr_class_tipo',
'siac_r_bil_elem_tipo_class_tip',
'siac_r_bil_elem_tipo_class_tip_elem_code',
'siac_r_bil_elem_tipo_attr_id_elem_code',
'siac_r_attr_entita',
'siac_r_bil_tipo_stato_op',
'siac_r_movgest_tipo_class_tip',
'siac_r_ordinativo_tipo_class_tip',
'siac_t_class',
'siac_t_soggetto',
'siac_r_soggetto_ruolo',
'siac_t_account',
'siac_t_gruppo',
'siac_r_gruppo_account',
'siac_r_gruppo_ruolo_op',
'siac_r_account_ruolo_op',
'siac_r_ruolo_op_azione',
'siac_t_periodo',
'siac_t_bil',
'siac_r_bil_fase_operativa',
'siac_r_gestione_ente',
'siac_t_report',
'siac_t_report_importi',
'siac_r_report_importi',
'siac_t_forma_giuridica',
'siac_t_nazione',
'siac_t_provincia',
'siac_t_comune',
'siac_r_comune_provincia',
'siac_r_comune_regione',
'siac_r_provincia_regione')
;*/

level:=1;

update bko_d_tables_to_delete set livello=level
where exists (
SELECT 1
  FROM information_schema.constraint_column_usage cu,
       pg_class c,
       pg_attribute a,
       pg_class c2,
       pg_attribute a2,
       information_schema.table_constraints tc,
       information_schema.referential_constraints rc,
       information_schema.table_constraints tc2,
       information_schema.constraint_column_usage cu2
  WHERE c.relname = tc.table_name AND
        a.attname = cu.column_name AND
        tc.constraint_name::text = cu.constraint_name::text AND
        a.attnum > 0 AND
        a.attrelid = c.oid AND
        c2.relname = tc2.table_name::name AND
        a2.attname = cu2.column_name::name AND
        tc2.constraint_name::text = cu2.constraint_name::text AND
        a2.attnum > 0 AND
        a2.attrelid = c2.oid AND
        rc.constraint_name::text = tc.constraint_name::text AND
        tc2.constraint_name::text = rc.unique_constraint_name::text AND
        tc.table_schema::text = tab_schema::text AND
        tc.constraint_type::text = 'FOREIGN KEY'::text
and        
         tc2.table_name=bko_d_tables_to_delete.nometabella
);

while datipresenti loop

  level:=LEVEL+1;

  raise notice 'livello %', LEVEL::varchar;


    if exists (select * from bko_d_tables_to_delete where livello=level-1) then
        update bko_d_tables_to_delete set livello=level
                where livello=level-1 and
                exists (
                SELECT 1
                  FROM information_schema.constraint_column_usage cu,
                       pg_class c,
                       pg_attribute a,
                       pg_class c2,
                       pg_attribute a2,
                       information_schema.table_constraints tc,
                       information_schema.referential_constraints rc,
                       information_schema.table_constraints tc2,
                       information_schema.constraint_column_usage cu2,
                       bko_d_tables_to_delete d1,
                       bko_d_tables_to_delete d2
                  WHERE 
                  d1.nometabella=tc.table_name
                  and
                   d2.nometabella=tc2.table_name
                   and d1.livello=d2.livello
                   and
                  c.relname = tc.table_name::name AND
                        a.attname = cu.column_name::name AND
                        tc.constraint_name::text = cu.constraint_name::text AND
                        a.attnum > 0 AND
                        a.attrelid = c.oid AND
                        c2.relname = tc2.table_name::name AND
                        a2.attname = cu2.column_name::name AND
                        tc2.constraint_name::text = cu2.constraint_name::text AND
                        a2.attnum > 0 AND
                        a2.attrelid = c2.oid AND
                        rc.constraint_name::text = tc.constraint_name::text AND
                        tc2.constraint_name::text = rc.unique_constraint_name::text AND
                        tc.table_schema::text = tab_schema::text AND
                        tc.constraint_type::text = 'FOREIGN KEY'::text
                and        
                         tc2.table_name=bko_d_tables_to_delete.nometabella
                          and tc.table_name<>tc2.table_name
                );
    else
          datipresenti:=false;
    end if;              

	
raise notice 'datipresenti %', datipresenti::varchar;

end loop;


/*for rec2 in select * from siac_tmp_tab_to_delete2
order by 2 asc,1 asc loop

stringone:='delete from '||rec2.nometabella||' where ente_proprietario_id='||ente_prop_id||';';
execute stringone;

end loop;


stringone3:='DROP TABLE bko_d_tables_to_delete;';

execute stringone3;

*/


exception
when no_data_found THEN
raise notice 'nessun dato trovato';
when others  THEN
 raise notice 'errore : %  - stato: % ', SQLERRM, SQLSTATE;


END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
SECURITY DEFINER
;
