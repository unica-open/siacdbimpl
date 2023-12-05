/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

-- SIAC-7541 23.04.2020 Sofia

select fnc_dba_add_column_params ('siac_dwh_impegno',  'cod_cdr_struttura_comp',  'VARCHAR(200)');
select fnc_dba_add_column_params ('siac_dwh_impegno',  'desc_cdr_struttura_comp',  'VARCHAR(500)');
select fnc_dba_add_column_params ('siac_dwh_impegno',  'cod_cdc_struttura_comp',  'VARCHAR(200)');
select fnc_dba_add_column_params ('siac_dwh_impegno',  'desc_cdc_struttura_comp',  'VARCHAR(500)');

select fnc_dba_add_column_params ('siac_dwh_subimpegno',  'cod_cdr_struttura_comp',  'VARCHAR(200)');
select fnc_dba_add_column_params ('siac_dwh_subimpegno',  'desc_cdr_struttura_comp',  'VARCHAR(500)');
select fnc_dba_add_column_params ('siac_dwh_subimpegno',  'cod_cdc_struttura_comp',  'VARCHAR(200)');
select fnc_dba_add_column_params ('siac_dwh_subimpegno',  'desc_cdc_struttura_comp',  'VARCHAR(500)');

select fnc_dba_add_column_params ('siac_dwh_accertamento',  'cod_cdr_struttura_comp',  'VARCHAR(200)');
select fnc_dba_add_column_params ('siac_dwh_accertamento',  'desc_cdr_struttura_comp',  'VARCHAR(500)');
select fnc_dba_add_column_params ('siac_dwh_accertamento',  'cod_cdc_struttura_comp',  'VARCHAR(200)');
select fnc_dba_add_column_params ('siac_dwh_accertamento',  'desc_cdc_struttura_comp',  'VARCHAR(500)');

select fnc_dba_add_column_params ('siac_dwh_subaccertamento',  'cod_cdr_struttura_comp',  'VARCHAR(200)');
select fnc_dba_add_column_params ('siac_dwh_subaccertamento',  'desc_cdr_struttura_comp',  'VARCHAR(500)');
select fnc_dba_add_column_params ('siac_dwh_subaccertamento',  'cod_cdc_struttura_comp',  'VARCHAR(200)');
select fnc_dba_add_column_params ('siac_dwh_subaccertamento',  'desc_cdc_struttura_comp',  'VARCHAR(500)');