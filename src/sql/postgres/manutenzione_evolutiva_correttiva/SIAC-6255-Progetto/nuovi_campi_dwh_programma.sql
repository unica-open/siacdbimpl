/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma', 'programma_responsabile_unico' , 'VARCHAR(500)');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma', 'programma_spazi_finanziari' , 'BOOLEAN');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma', 'programma_anno_bilancio' , 'VARCHAR(4)');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma', 'programma_affidamento_code' , 'VARCHAR(200)');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma', 'programma_affidamento_desc' , 'VARCHAR(500)');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma', 'programma_tipo_code' , 'VARCHAR(200)');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma', 'programma_tipo_desc' , 'VARCHAR(500)');