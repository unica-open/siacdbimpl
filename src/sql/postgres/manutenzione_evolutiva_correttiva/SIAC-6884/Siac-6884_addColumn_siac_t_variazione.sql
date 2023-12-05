/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿SELECT * FROM siac.fnc_dba_add_column_params ('siac.siac_t_variazione', 'data_invio_proposta' , 'TIMESTAMP WITHOUT TIME ZONE');
SELECT * FROM siac.fnc_dba_add_column_params ('siac.siac_t_variazione', 'data_apertura_bozza' , 'TIMESTAMP WITHOUT TIME ZONE');
SELECT * FROM siac.fnc_dba_add_column_params ('siac.siac_t_variazione', 'data_chiusura_bozza' , 'TIMESTAMP WITHOUT TIME ZONE');