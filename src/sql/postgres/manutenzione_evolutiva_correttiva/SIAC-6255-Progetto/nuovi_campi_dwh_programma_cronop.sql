/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- siac_t_programma
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_responsabile_unico' , 'VARCHAR(500)');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_spazi_finanziari' , 'BOOLEAN');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_anno_bilancio' , 'VARCHAR(4)');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_affidamento_code' , 'VARCHAR(200)');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_affidamento_desc' , 'VARCHAR(500)');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_tipo_code' , 'VARCHAR(200)');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_tipo_desc' , 'VARCHAR(500)');
-- siac_t_cronop
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_cronop_data_appfat' , 'TIMESTAMP WITHOUT TIME ZONE');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_cronop_data_appdef' , 'TIMESTAMP WITHOUT TIME ZONE');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_cronop_data_appesec' , 'TIMESTAMP WITHOUT TIME ZONE');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_cronop_data_avviopr' , 'TIMESTAMP WITHOUT TIME ZONE');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_cronop_data_agglav' , 'TIMESTAMP WITHOUT TIME ZONE');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_cronop_data_inizlav' , 'TIMESTAMP WITHOUT TIME ZONE');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_cronop_data_finelav' , 'TIMESTAMP WITHOUT TIME ZONE');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_cronop_giorni_dur' , 'integer');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_cronop_data_coll' , 'TIMESTAMP WITHOUT TIME ZONE');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_cronop_gest_quad_eco' , 'BOOLEAN');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_cronop_us_per_fpv_pr' , 'BOOLEAN');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_cronop_ann_atto_amm' , 'VARCHAR(4)');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_cronop_num_atto_amm' , 'VARCHAR(500)');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_cronop_ogg_atto_amm' , 'VARCHAR(500)');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_cronop_nte_atto_amm' , 'VARCHAR(500)');

SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_cronop_tpc_atto_amm' , 'VARCHAR(200)');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_cronop_tpd_atto_amm' , 'VARCHAR(500)');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_cronop_stc_atto_amm' , 'VARCHAR(200)');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_cronop_std_atto_amm' , 'VARCHAR(500)');

SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_cronop_crc_atto_amm' , 'VARCHAR(200)');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_cronop_crd_atto_amm' , 'VARCHAR(500)');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_cronop_cdc_atto_amm' , 'VARCHAR(200)');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_cronop_cdd_atto_amm' , 'VARCHAR(500)');