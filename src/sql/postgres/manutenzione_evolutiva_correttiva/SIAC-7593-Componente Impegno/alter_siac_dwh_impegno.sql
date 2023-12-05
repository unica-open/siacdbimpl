/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

-- SIAC-7593 Sofia 06.05.2020 -- componente tipo impegno
 /* comp_tipo_desc        VARCHAR(500) ,
  comp_tipo_macro_code  VARCHAR(200),
  comp_tipo_macro_desc  VARCHAR(500),
  comp_tipo_sotto_tipo_code  VARCHAR(200),
  comp_tipo_sotto_tipo_desc  VARCHAR(500),
  comp_tipo_ambito_code VARCHAR(200),
  comp_tipo_ambito_desc VARCHAR(500),
  comp_tipo_fonte_code  VARCHAR(200),
  comp_tipo_fonte_desc  VARCHAR(500),
  comp_tipo_fase_code   VARCHAR(200),
  comp_tipo_fase_desc   VARCHAR(500),
  comp_tipo_def_code    VARCHAR(200),
  comp_tipo_def_desc    VARCHAR(500),
  comp_tipo_anno        INTEGER*/

  SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_code', 'VARCHAR(200)');
  SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_desc', 'VARCHAR(500)');
  SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_macro_code', 'VARCHAR(200)');
  SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_macro_desc', 'VARCHAR(500)');
  SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_sotto_tipo_code', 'VARCHAR(200)');
  SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_sotto_tipo_desc', 'VARCHAR(500)');
  SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_ambito_code', 'VARCHAR(200)');
  SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_ambito_desc', 'VARCHAR(500)');
  SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_fonte_code', 'VARCHAR(200)');
  SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_fonte_desc', 'VARCHAR(500)');
  SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_fase_code', 'VARCHAR(200)');
  SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_fase_desc', 'VARCHAR(500)');
  SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_def_code', 'VARCHAR(200)');
  SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_def_desc', 'VARCHAR(500)');
  SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_gest_aut', 'VARCHAR(50)');
  SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_anno', 'INTEGER');

  SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_code', 'VARCHAR(200)');
  SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_desc', 'VARCHAR(500)');
  SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_macro_code', 'VARCHAR(200)');
  SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_macro_desc', 'VARCHAR(500)');
  SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_sotto_tipo_code', 'VARCHAR(200)');
  SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_sotto_tipo_desc', 'VARCHAR(500)');
  SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_ambito_code', 'VARCHAR(200)');
  SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_ambito_desc', 'VARCHAR(500)');
  SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_fonte_code', 'VARCHAR(200)');
  SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_fonte_desc', 'VARCHAR(500)');
  SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_fase_code', 'VARCHAR(200)');
  SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_fase_desc', 'VARCHAR(500)');
  SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_def_code', 'VARCHAR(200)');
  SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_def_desc', 'VARCHAR(500)');
  SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_gest_aut', 'VARCHAR(50)');

  SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_anno', 'INTEGER');