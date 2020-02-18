/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
select *
from siac_dwh_programma_cronop

alter table siac_dwh_programma_cronop
add  programma_cronop_stato_code VARCHAR(200),
add  programma_cronop_stato_desc VARCHAR(500)

select fnc_dba_add_column_params ('siac_dwh_programma_cronop',  'programma_cronop_stato_code',  'VARCHAR(200)');
select fnc_dba_add_column_params ('siac_dwh_programma_cronop',  'programma_cronop_stato_desc',  'VARCHAR(500)');