/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

SELECT * from fnc_dba_add_column_params ('siac_dwh_capitolo_fpv', 'data_elaborazione' , 'TIMESTAMP WITHOUT TIME ZONE DEFAULT now()');

