/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma', 'programma_sac_tipo' , 'VARCHAR(200)');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma', 'programma_sac_code' , 'VARCHAR(500)');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma', 'programma_sac_desc' , 'VARCHAR(500)');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma', 'programma_cup' , 'VARCHAR(200)');


SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_sac_tipo' , 'VARCHAR(200)');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_sac_code' , 'VARCHAR(500)');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_sac_desc' , 'VARCHAR(500)');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_cup' , 'VARCHAR(200)');

SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'entrata_prevista_cronop_entrata' , 'VARCHAR(200)');



SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_cronop_descr_spesa' , 'VARCHAR(500)');
SELECT * FROM fnc_dba_add_column_params ('siac_dwh_programma_cronop', 'programma_cronop_descr_entrata' , 'VARCHAR(500)');


