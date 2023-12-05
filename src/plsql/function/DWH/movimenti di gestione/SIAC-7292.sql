/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

--  flagdareanno         VARCHAR(1), -- 19.02.2020 Sofia jira siac-7292

--  siac_dwh_subimpegno
--  siac_dwh_impegno
--  siac_dwh_accertamento
--  siac_dwh_subaccertamento

select fnc_dba_add_column_params ('siac_dwh_impegno',  'flagdareanno',  'VARCHAR(1)');
select fnc_dba_add_column_params ('siac_dwh_subimpegno',  'flagdareanno',  'VARCHAR(1)');
select fnc_dba_add_column_params ('siac_dwh_accertamento',  'flagdareanno',  'VARCHAR(1)');
select fnc_dba_add_column_params ('siac_dwh_subaccertamento',  'flagdareanno',  'VARCHAR(1)');

-- select fnc_dba_add_column_params ('siac_t_modifica',  'elab_ror_reanno',  'VARCHAR(1)');


