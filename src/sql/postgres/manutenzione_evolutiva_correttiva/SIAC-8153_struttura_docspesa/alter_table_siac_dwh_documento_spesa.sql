/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿select 
fnc_dba_add_column_params('siac_dwh_documento_spesa', 'cod_cdc_sub', 'VARCHAR(200)');
select 
fnc_dba_add_column_params('siac_dwh_documento_spesa', 'desc_cdc_sub', 'VARCHAR(500)');


select 
fnc_dba_add_column_params('siac_dwh_documento_spesa', 'cod_cdr_sub', 'VARCHAR(200)');
select 
fnc_dba_add_column_params('siac_dwh_documento_spesa', 'desc_cdr_sub', 'VARCHAR(500)');


select 
fnc_dba_add_column_params('siac_dwh_st_documento_spesa', 'cod_cdc_sub', 'VARCHAR(200)');
select 
fnc_dba_add_column_params('siac_dwh_st_documento_spesa', 'desc_cdc_sub', 'VARCHAR(500)');


select 
fnc_dba_add_column_params('siac_dwh_st_documento_spesa', 'cod_cdr_sub', 'VARCHAR(200)');
select 
fnc_dba_add_column_params('siac_dwh_st_documento_spesa', 'desc_cdr_sub', 'VARCHAR(500)');

