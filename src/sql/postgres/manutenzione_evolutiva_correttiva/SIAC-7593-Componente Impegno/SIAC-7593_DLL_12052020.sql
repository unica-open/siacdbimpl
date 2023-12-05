/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- siac_dwh_impegno
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_code', 'VARCHAR(200)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_desc', 'VARCHAR(500)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_macro_code', 'VARCHAR(200)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_macro_desc', 'VARCHAR(500)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_sotto_tipo_code', 'VARCHAR(200)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_sotto_tipo_desc', 'VARCHAR(500)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_ambito_code', 'VARCHAR(200)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_ambito_desc', 'VARCHAR(500)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_fonte_code', 'VARCHAR(200)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_fonte_desc', 'VARCHAR(500)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_fase_code', 'VARCHAR(200)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_fase_desc', 'VARCHAR(500)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_def_code', 'VARCHAR(200)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_def_desc', 'VARCHAR(500)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_gest_aut', 'VARCHAR(50)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_impegno', 'comp_tipo_anno', 'INTEGER');

-- siac_dwh_subimpegno
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_code', 'VARCHAR(200)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_desc', 'VARCHAR(500)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_macro_code', 'VARCHAR(200)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_macro_desc', 'VARCHAR(500)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_sotto_tipo_code', 'VARCHAR(200)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_sotto_tipo_desc', 'VARCHAR(500)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_ambito_code', 'VARCHAR(200)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_ambito_desc', 'VARCHAR(500)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_fonte_code', 'VARCHAR(200)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_fonte_desc', 'VARCHAR(500)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_fase_code', 'VARCHAR(200)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_fase_desc', 'VARCHAR(500)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_def_code', 'VARCHAR(200)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_def_desc', 'VARCHAR(500)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_gest_aut', 'VARCHAR(50)');
SELECT * FROM  fnc_dba_add_column_params ( 'siac_dwh_subimpegno', 'comp_tipo_anno', 'INTEGER');


-- fase_bil_t_gest_apertura_pluri
SELECT * FROM  fnc_dba_add_column_params ( 'fase_bil_t_gest_apertura_pluri', 'elem_det_comp_tipo_id', 'INTEGER');
SELECT * FROM  fnc_dba_add_column_params ( 'fase_bil_t_gest_apertura_pluri', 'elem_orig_det_comp_tipo_id', 'INTEGER');
SELECT * FROM  fnc_dba_add_fk_constraint ( 'fase_bil_t_gest_apertura_pluri', 'siac_d_elem_det_comp_tipo_fase_bil_t_gest_ape_pluri_id', 'elem_det_comp_tipo_id', 'siac_d_bil_elem_det_comp_tipo', 'elem_det_comp_tipo_id');
SELECT * FROM  fnc_dba_add_fk_constraint ( 'fase_bil_t_gest_apertura_pluri', 'siac_d_elem_det_comp_tipo_fase_bil_t_gest_ape_pluri_id_1', 'elem_orig_det_comp_tipo_id', 'siac_d_bil_elem_det_comp_tipo', 'elem_det_comp_tipo_id');


-- fase_bil_t_gest_apertura_liq_imp
SELECT * FROM  fnc_dba_add_column_params ( 'fase_bil_t_gest_apertura_liq_imp', 'elem_det_comp_tipo_id', 'INTEGER');
SELECT * FROM  fnc_dba_add_column_params ( 'fase_bil_t_gest_apertura_liq_imp', 'elem_orig_det_comp_tipo_id', 'INTEGER');
SELECT * FROM  fnc_dba_add_fk_constraint ( 'fase_bil_t_gest_apertura_liq_imp', 'siac_d_elem_det_comp_tipo_fase_bil_t_gest_ape_liq_imp_id', 'elem_det_comp_tipo_id', 'siac_d_bil_elem_det_comp_tipo', 'elem_det_comp_tipo_id');
SELECT * FROM  fnc_dba_add_fk_constraint ( 'fase_bil_t_gest_apertura_liq_imp', 'siac_d_elem_det_comp_tipo_fase_bil_t_gest_ape_liq_imp_id_1', 'elem_orig_det_comp_tipo_id', 'siac_d_bil_elem_det_comp_tipo', 'elem_det_comp_tipo_id');

-- fase_bil_d_elaborazione_tipo
SELECT * FROM  fnc_dba_add_column_params ( 'fase_bil_d_elaborazione_tipo', 'fase_bil_elab_tipo_param', 'VARCHAR(200)');

update fase_bil_d_elaborazione_tipo tipo
set    fase_bil_elab_tipo_param='Da attribuire|parte fresca|finanziata da FPV da ROR|finanziata da FPV non ROR',
       data_modifica=now(),
       login_operazione=tipo.login_operazione||'-SIAC-7593'
where tipo.ente_proprietario_id=2
and   tipo.fase_bil_elab_tipo_code='APE_GEST_REIMP';

update fase_bil_d_elaborazione_tipo tipo
set    fase_bil_elab_tipo_param='Da attribuire|NUOVA RICHIESTA|FPV APPLICATO|FPV APPLICATO',
       data_modifica=now(),
       login_operazione=tipo.login_operazione||'-SIAC-7593'
where tipo.ente_proprietario_id=3
and   tipo.fase_bil_elab_tipo_code='APE_GEST_REIMP';

update fase_bil_d_elaborazione_tipo tipo
set    fase_bil_elab_tipo_param='GENERICA',
       data_modifica=now(),
       login_operazione=tipo.login_operazione||'-SIAC-7593'
where tipo.ente_proprietario_id in (4,5,10,13,14,16)
and   tipo.fase_bil_elab_tipo_code='APE_GEST_REIMP';

-- fase_bil_t_reimputazione
SELECT * FROM  fnc_dba_add_column_params ( 'fase_bil_t_reimputazione', 'elem_det_comp_tipo_id', 'INTEGER');
SELECT * FROM  fnc_dba_add_column_params ( 'fase_bil_t_reimputazione', 'importo_modifica_entrata', 'numeric');
SELECT * FROM  fnc_dba_add_column_params ( 'fase_bil_t_reimputazione', 'importo_reimputato', 'numeric');
SELECT * FROM  fnc_dba_add_column_params ( 'fase_bil_t_reimputazione', 'coll_mod_entrata', 'boolean');
SELECT * FROM  fnc_dba_add_column_params ( 'fase_bil_t_reimputazione', 'coll_det_mod_entrata', 'boolean');

SELECT * FROM  fnc_dba_add_fk_constraint ( 'fase_bil_t_reimputazione', 'siac_d_elem_det_comp_tipo_fase_bil_t_reimputazione_id', 'elem_det_comp_tipo_id', 'siac_d_bil_elem_det_comp_tipo', 'elem_det_comp_tipo_id');