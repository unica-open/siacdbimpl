/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


SELECT * FROM fnc_dba_add_column_params('siac_t_soggetto_mod', 'soggetto_tipo_fonte_durc', 'CHAR(1)');

SELECT * FROM fnc_dba_add_column_params('siac_t_soggetto_mod', 'soggetto_fine_validita_durc', 'DATE');

SELECT * FROM fnc_dba_add_column_params('siac_t_soggetto_mod', 'soggetto_fonte_durc_manuale_classif_id', 'INTEGER');

SELECT * FROM fnc_dba_add_column_params('siac_t_soggetto_mod', 'soggetto_fonte_durc_automatica', 'TEXT');

SELECT * FROM fnc_dba_add_column_params('siac_t_soggetto_mod', 'soggetto_note_durc', 'TEXT');

COMMENT ON COLUMN siac_t_soggetto_mod.soggetto_tipo_fonte_durc IS 'A: automatica, M: manuale';

SELECT * FROM fnc_dba_add_check_constraint(
	'siac_t_soggetto_mod',
    'siac_t_soggetto_mod_soggetto_tipo_fonte_durc_chk',
    'soggetto_tipo_fonte_durc IN (''A'', ''M'')'
);

SELECT * FROM fnc_dba_add_fk_constraint (
	'siac_t_soggetto_mod',
	'siac_t_class_siac_t_soggetto',
    'soggetto_fonte_durc_manuale_classif_id',
  	'siac_t_class',
    'classif_id'
);




