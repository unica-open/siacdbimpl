/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

SELECT * from fnc_dba_add_column_params ('siac_t_soggetto', 'email_pec', 'varchar(256)');

SELECT * from fnc_dba_add_column_params ('siac_t_soggetto', 'cod_destinatario', 'varchar(7)');

SELECT * from fnc_dba_add_column_params ('siac_t_soggetto', 'codice_pa', 'varchar(10)');

SELECT * from fnc_dba_add_column_params ('siac_t_doc', 'stato_sdi', 'varchar(2)');

SELECT * from fnc_dba_add_column_params ('siac_t_doc', 'esito_stato_sdi', 'varchar(500)');

SELECT * from fnc_dba_add_column_params ('siac_t_soggetto_mod', 'email_pec', 'varchar(256)');

SELECT * from fnc_dba_add_column_params ('siac_t_soggetto_mod', 'cod_destinatario', 'varchar(7)');

SELECT * from fnc_dba_add_column_params ('siac_t_soggetto_mod', 'codice_pa', 'varchar(10)');