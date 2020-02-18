/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_dba_add_fk_constraint (
  table_in text,
  constraint_in text,
  column_in text,
  table_ref text,
  column_ref text
)


RETURNS text AS
$body$
declare
 
query_in text;
esito text;
begin
 
 select  'ALTER TABLE ' || table_in || ' ADD CONSTRAINT ' || constraint_in || ' FOREIGN KEY (' || column_in ||') ' ||
		 ' REFERENCES ' || table_ref || '(' || column_ref || ') ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE' 
		 into query_in
 where 
 not exists 
 (
 SELECT 1
	FROM information_schema.table_constraints tc
	WHERE tc.constraint_schema='siac'
	AND tc.table_schema='siac'
	AND tc.constraint_type='FOREIGN KEY' 
	AND tc.table_name=table_in
	AND tc.constraint_name=constraint_in
 );

 if query_in is not null then
 	esito:='fk constraint creato';
  	execute query_in;
    
 else 
	esito:='fk constraint già presente';
 end if;
 
 return esito;

exception
    when RAISE_EXCEPTION THEN
    esito:=substring(upper(SQLERRM) from 1 for 2500);
        return esito;
	when others  THEN
	esito:=' others - ' ||substring(upper(SQLERRM) from 1 for 2500);
        return esito;


end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;




-- ######################################################






SELECT * FROM fnc_dba_add_column_params('siac_t_soggetto', 'soggetto_tipo_fonte_durc', 'CHAR(1)');

SELECT * FROM fnc_dba_add_column_params('siac_t_soggetto', 'soggetto_fine_validita_durc', 'DATE');

SELECT * FROM fnc_dba_add_column_params('siac_t_soggetto', 'soggetto_fonte_durc_manuale_classif_id', 'INTEGER');

SELECT * FROM fnc_dba_add_column_params('siac_t_soggetto', 'soggetto_fonte_durc_automatica', 'TEXT');

SELECT * FROM fnc_dba_add_column_params('siac_t_soggetto', 'soggetto_note_durc', 'TEXT');

COMMENT ON COLUMN siac.siac_t_soggetto.soggetto_tipo_fonte_durc IS 'A: automatica, M: manuale';

SELECT * FROM fnc_dba_add_check_constraint(
	'siac_t_soggetto',
    'siac_t_soggetto_soggetto_tipo_fonte_durc_chk',
    'soggetto_tipo_fonte_durc IN (''A'', ''M'')'
);

SELECT * FROM fnc_dba_add_fk_constraint (
	'siac_t_soggetto',
	'siac_t_class_siac_t_soggetto',
    'soggetto_fonte_durc_manuale_classif_id',
  	'siac_t_class',
    'classif_id'
);




