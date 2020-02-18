/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
SELECT fnc_dba_add_column_params(
	'siac_t_ordinativo', 
	'ord_da_trasmettere', 
	'BOOLEAN NOT NULL DEFAULT TRUE');