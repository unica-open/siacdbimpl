/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
SELECT * FROM siac.fnc_dba_add_column_params ('siac.siac_t_variazione', 'data_apertura_proposta' , 'TIMESTAMP WITHOUT TIME ZONE');
SELECT * FROM siac.fnc_dba_add_column_params ('siac.siac_t_variazione', 'classif_id' , 'INTEGER');
SELECT * FROM siac.fnc_dba_add_fk_constraint('siac.siac_t_variazione', 'siac_t_class_siac_t_variazione', 'classif_id', 'siac.siac_t_class', 'classif_id');
SELECT * FROM siac.fnc_dba_add_column_params ('siac.siac_t_variazione', 'flag_consiglio', 'BOOLEAN DEFAULT false NOT NULL');
SELECT * FROM siac.fnc_dba_add_column_params ('siac.siac_t_variazione', 'flag_giunta', 'BOOLEAN DEFAULT false NOT NULL');
