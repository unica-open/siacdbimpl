/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

SELECT siac.fnc_dba_add_column_params(
	'siac_t_voce_conf_indicatori_sint', 
    'voce_conf_ind_tipo',
    'VARCHAR(1)'
);



  
SELECT * FROM siac.fnc_dba_add_check_constraint 
('siac_t_voce_conf_indicatori_sint', 
'siac_t_voce_conf_indicatori_sint_chk', 
'voce_conf_ind_tipo IN (''P'', ''R'')');

